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
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(hex: "FFE8F8"), // Soft pale rose
                        Color(hex: "F1F4FF"), // Soft lavender
                        Color(hex: "FEFEFE")  // Pure white
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    if histories.isEmpty {
                        emptyState
                    } else {
                        List {
                            ForEach(histories) { history in
                                ZStack {
                                    HistoryCard(history: history)
                                    
                                    NavigationLink(destination: SkinAnalysisResultView(
                                        image:            history.uiImage ?? UIImage(),
                                        result:           SkinAnalysisResult(
                                            skinType:           history.skinType,
                                            skinTypeConfidence: history.skinTypeConfidence,
                                            acneLevel:         nil,
                                            acneConfidence:    nil,
                                            acneBoundingBoxes: history.acneBoundingBoxes
                                        ),
                                        clahePreview:     nil,
                                        isFromHistory:    true,
                                        onDone:           {}
                                    )) {
                                        EmptyView()
                                    }
                                    .opacity(0.0)
                                }
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("History")
                        .font(.headline)
                        .foregroundStyle(.black)
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                        }
                        .foregroundColor(Color(hex: "5A4C47"))
                    }
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
