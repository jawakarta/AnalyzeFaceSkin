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
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(hex: "F3B8A5"), // Soft Warm Peach
                    Color(hex: "EBD4E2"), // Pastel Creamy Pink
                    Color(hex: "D7D3EA")  // Gentle Lavender
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                headerView

                if histories.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(histories) { history in
                            HistoryCard(history: history)
                                .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                        .onDelete(perform: deleteHistory)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
    }

    private func deleteHistory(at offsets: IndexSet) {
        for index in offsets {
            let history = histories[index]
            modelContext.delete(history)
        }
        try? modelContext.save()
    }

    private var headerView: some View {
        HStack {
            Text("History")
                .font(.system(.title2, design: .rounded))
                .bold()
                .foregroundColor(Color(hex: "3A2E2B"))

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: "5A4C47"))
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.15))
        .overlay(
            Rectangle()
                .fill(Color.black.opacity(0.06))
                .frame(height: 1),
            alignment: .bottom
        )
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundColor(Color(hex: "75635F").opacity(0.5))
            Text("No History Yet")
                .font(.system(.title3, design: .rounded))
                .foregroundColor(Color(hex: "3A2E2B"))
                .bold()
            Text("Your scan results will appear here")
                .font(.system(.footnote, design: .rounded))
                .foregroundColor(Color(hex: "75635F"))
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
                    .fill(Color(hex: "ECEAF8"))
                    .frame(width: 64, height: 64)
                    .overlay(
                        Image(systemName: "face.smiling")
                            .foregroundColor(Color(hex: "5E52B7"))
                    )
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(history.skinType.capitalized)
                    .font(.system(.headline, design: .rounded))
                    .foregroundColor(Color(hex: "3A2E2B"))

                Text(String(format: "%.0f%% Match", history.skinTypeConfidence * 100))
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(Color(hex: "5E52B7"))
                    .bold()

                Text(history.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(Color(hex: "75635F"))
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(Color(hex: "A39A96"))
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: SkinAnalysisHistory.self, inMemory: true)
}
