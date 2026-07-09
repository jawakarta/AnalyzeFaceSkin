# Face Capture App PRD

## Project Overview

Develop an iOS application using **SwiftUI** with **MVVM Architecture** to perform intelligent face capture for a Skin Analyzer application.

The application should guide users to position their face correctly using Vision Framework, visual overlay, text guidance, and voice instructions before capturing a high-quality image.

---

# Technology Stack

- SwiftUI
- Vision Framework
- AVFoundation
- PhotosUI
- Photos
- Combine

Minimum iOS Version:

- iOS 17+

---

# Architecture

The project must strictly follow MVVM.

```
App
│
├── Views
├── ViewModels
├── Models
├── Services
├── Helpers
├── Managers
├── Extensions
└── Resources
```

---

# Coding Standards

## File Size

Every Swift file must contain **less than 200 lines of code**.

If a file exceeds 200 lines, split it into Helper, Service, or Component.

---

## Function Rules

Each function should have only one responsibility.

Maximum 20–25 lines per function.

Avoid giant methods.

---

## View Rules

Views are responsible only for UI.

Views must never:

- Detect faces
- Capture photos
- Process images
- Handle Vision requests

Views should only observe ViewModels.

---

## ViewModel Rules

ViewModels coordinate Services.

They expose state using:

- @Published
- ObservableObject

ViewModels should never directly use AVFoundation APIs.

---

## Services

Business logic belongs inside Services.

Required Services:

- CameraService
- VisionService
- VoiceGuideService
- PhotoLibraryService
- PermissionService

---

# Camera

Use AVFoundation.

Requirements:

- Fullscreen camera preview
- Front camera by default
- High resolution capture
- Real-time frame output
- Manual capture
- Auto capture
- Photo import
- Save to Photos

---

# Vision

Use Vision Framework.

Detect:

- Face
- Face Bounding Box
- Pitch
- Roll
- Yaw

Detection should run continuously.

---

# Face Alignment

Validate:

- Left / Right
- Up / Down
- Distance
- Rotation

Only allow capture when all conditions pass.

---

# Visual Overlay

Display:

- Face oval
- Progress ring
- Face bounding box (optional)
- Guide text

Oval color:

Gray

↓

Yellow

↓

Green

---

# Text Guide

Possible messages:

- Move Left
- Move Right
- Move Up
- Move Down
- Move Closer
- Move Back
- Look Straight
- Hold Still
- Ready

---

# Voice Guide

Use AVSpeechSynthesizer.

Examples:

- Move your face left.
- Move closer.
- Hold still.
- Perfect.
- Capturing photo.

Voice guidance should not repeat the same sentence within two seconds.

---

# Auto Capture

Automatically capture when:

- Face detected
- Face centered
- Distance valid
- Rotation valid
- Stable for 2 seconds

---

# Photo Library

Support:

- Import image
- Save captured image

---

# Permissions

Handle:

- Camera
- Photos

Display friendly error messages.

---

# UI Layout

Top

- Status
- Guide Text

Center

- Face Oval
- Progress Ring

Bottom

- Gallery
- Capture
- Settings

Camera preview must always be fullscreen.

---

# Folder Structure

```
FaceCaptureApp
│
├── App
├── Views
├── ViewModels
├── Models
├── Services
├── Helpers
├── Managers
├── Extensions
└── Resources
```

---

# Future Expansion

The architecture must support:

- CoreML Skin Classification
- ARKit Face Alignment
- Multi Angle Capture
- Image Quality Validation
- Cloud Upload
- Face Landmark Detection

---

# Acceptance Criteria

- Fullscreen camera
- Real-time face detection
- Smooth overlay
- Voice guidance
- Text guidance
- Auto capture
- Manual capture
- Photo import
- Photo save
- MVVM architecture
- Maximum 200 lines per Swift file
- Small reusable functions
