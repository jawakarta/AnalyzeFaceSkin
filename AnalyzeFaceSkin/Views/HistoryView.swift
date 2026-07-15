//
//  HistoryView.swift
//  AnalyzeFaceSkin
//
//  Created by Bayu Krisna Dwihadi Fahrizal on 14/07/26.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \SkinAnalysisHistory.createdAt, order: .reverse) private var histories: [SkinAnalysisHistory]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                headerView

                if histories.isEmpty {
                    emptyState
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(histories) { history in
                                HistoryCard(history: history)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    }
                }
            }
        }
    }

    private var headerView: some View {
        HStack {
            Text("History")
                .font(.system(.title2, design: .rounded))
                .bold()
                .foregroundColor(.white)

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.03))
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.1))
                .frame(height: 1),
            alignment: .bottom
        )
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundColor(.white.opacity(0.3))
            Text("No History Yet")
                .font(.system(.title3, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
            Text("Your scan results will appear here")
                .font(.system(.footnote))
                .foregroundColor(.white.opacity(0.3))
            Spacer()
        }
    }
}

private struct HistoryCard: View {
    let history: SkinAnalysisHistory

    var body: some View {
        HStack(spacing: 16) {
            if let image = history.uiImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: "face.smiling")
                            .foregroundColor(.white.opacity(0.3))
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(history.skinType.capitalized)
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(.white)

                Text(String(format: "%.0f%% Match", history.skinTypeConfidence * 100))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.cyan)

                Text(history.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(.caption2))
                    .foregroundColor(.white.opacity(0.4))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: SkinAnalysisHistory.self, inMemory: true)
}
