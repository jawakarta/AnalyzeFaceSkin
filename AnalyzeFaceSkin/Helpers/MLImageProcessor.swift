//
//  MLImageProcessor.swift
//  AnalyzeFaceSkin
//
//  Created by Vinka Alrezky As on 14/07/26.
//

import UIKit
import CoreML

class MLImageProcessor {
    /// Converts a UIImage into a float32 MLMultiArray of shape [1, 3, 224, 224] with ImageNet normalization.
    static func makeMultiArray(from image: UIImage, width: Int = 224, height: Int = 224) -> MLMultiArray? {
        let size = CGSize(width: width, height: height)
        UIGraphicsBeginImageContextWithOptions(size, true, 1.0)
        image.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let cgImage = resizedImage?.cgImage else { return nil }
        
        // Explicit RGB space and bytes buffer layout to guarantee standard RGBA structure
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var rawData = [UInt8](repeating: 0, count: width * height * 4)
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        
        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else {
            return nil
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Create MLMultiArray of shape [1, 3, height, width]
        guard let multiArray = try? MLMultiArray(
            shape: [1, 3, NSNumber(value: height), NSNumber(value: width)],
            dataType: .float32
        ) else {
            return nil
        }
        
        let ptr = UnsafeMutablePointer<Float>(OpaquePointer(multiArray.dataPointer))
        
        // Extract pixels, normalize, and populate MultiArray in planar order [C, Y, X]
        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                let r = Float(rawData[offset]) / 255.0
                let g = Float(rawData[offset + 1]) / 255.0
                let b = Float(rawData[offset + 2]) / 255.0
                
                // ImageNet standard normalization (mean & std)
                let rNorm = (r - 0.485) / 0.229
                let gNorm = (g - 0.456) / 0.224
                let bNorm = (b - 0.406) / 0.225
                
                let rIndex = 0 * height * width + y * width + x
                let gIndex = 1 * height * width + y * width + x
                let bIndex = 2 * height * width + y * width + x
                
                ptr[rIndex] = rNorm
                ptr[gIndex] = gNorm
                ptr[bIndex] = bNorm
            }
        }
        
        return multiArray
    }
}
