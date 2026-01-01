//
//  BallPickerView.swift
//  BowlerTrax
//
//  View for selecting a ball from the catalog or creating a custom ball profile
//

import SwiftUI
import SwiftData

// MARK: - Ball Picker View

struct BallPickerView: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    // MARK: - Services

    @StateObject private var catalogService = BallCatalogService.shared

    // MARK: - State

    @State private var searchText = ""
    @State private var selectedBrand: String?
    @State private var showingCustomBallSheet = false
    @State private var selectedBall: CatalogBall?
    @State private var showingConfirmation = false

    // MARK: - Computed Properties

    private var filteredBalls: [CatalogBall] {
        catalogService.search(query: searchText, brand: selectedBrand)
    }

    private var groupedBalls: [(brand: String, balls: [CatalogBall])] {
        if let brand = selectedBrand, !brand.isEmpty {
            // Single brand selected - no grouping
            return [(brand: brand, balls: filteredBalls.sorted { $0.name < $1.name })]
        }

        // Group by brand
        let grouped = Dictionary(grouping: filteredBalls) { $0.brand }
        return grouped.keys.sorted().map { brand in
            (brand: brand, balls: grouped[brand]!.sorted { $0.name < $1.name })
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Group {
                if catalogService.isLoading {
                    loadingView
                } else if let error = catalogService.error {
                    errorView(error)
                } else if catalogService.balls.isEmpty {
                    emptyView
                } else {
                    ballListView
                }
            }
            .background(Color.btBackground)
            .navigationTitle("Select Ball")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.btPrimary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCustomBallSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .foregroundColor(.btPrimary)
                }
            }
            .searchable(text: $searchText, prompt: "Search balls...")
            .task {
                await catalogService.loadCatalog()
            }
            .sheet(isPresented: $showingCustomBallSheet) {
                CustomBallSheet { profile in
                    createBallProfile(from: profile)
                }
            }
            .alert("Add Ball", isPresented: $showingConfirmation, presenting: selectedBall) { ball in
                Button("Cancel", role: .cancel) {
                    selectedBall = nil
                }
                Button("Add") {
                    if let ball = selectedBall {
                        createBallProfile(fromCatalog: ball)
                    }
                }
            } message: { ball in
                Text("Add \(ball.displayName) to your ball profiles?")
            }
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        VStack(spacing: BTSpacing.lg) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.btPrimary)

            Text("Loading ball catalog...")
                .font(BTFont.body())
                .foregroundColor(.btTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ error: BallCatalogError) -> some View {
        VStack(spacing: BTSpacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.btWarning)

            Text("Failed to Load Catalog")
                .font(BTFont.h3())
                .foregroundColor(.btTextPrimary)

            Text(error.localizedDescription)
                .font(BTFont.body())
                .foregroundColor(.btTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, BTSpacing.xl)

            BTActionButton.primary(title: "Retry", icon: "arrow.clockwise") {
                Task {
                    await catalogService.reload()
                }
            }
            .padding(.horizontal, BTSpacing.xl)

            Button("Create Custom Ball") {
                showingCustomBallSheet = true
            }
            .font(BTFont.body())
            .foregroundColor(.btPrimary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: BTSpacing.lg) {
            Image(systemName: "circle.slash")
                .font(.system(size: 48))
                .foregroundColor(.btTextMuted)

            Text("No Balls Found")
                .font(BTFont.h3())
                .foregroundColor(.btTextPrimary)

            Text("The ball catalog is empty. Create a custom ball profile instead.")
                .font(BTFont.body())
                .foregroundColor(.btTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, BTSpacing.xl)

            BTActionButton.primary(title: "Create Custom Ball", icon: "plus") {
                showingCustomBallSheet = true
            }
            .padding(.horizontal, BTSpacing.xl)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var ballListView: some View {
        VStack(spacing: 0) {
            // Brand filter
            brandFilterView
                .padding(.horizontal, BTSpacing.md)
                .padding(.vertical, BTSpacing.sm)

            // Ball list
            List {
                ForEach(groupedBalls, id: \.brand) { group in
                    Section {
                        ForEach(group.balls) { ball in
                            BallRowView(ball: ball)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedBall = ball
                                    showingConfirmation = true
                                }
                                .listRowBackground(Color.btSurface)
                        }
                    } header: {
                        if selectedBrand == nil {
                            Text(group.brand)
                                .font(BTFont.labelSmall())
                                .foregroundColor(.btTextMuted)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
    }

    private var brandFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: BTSpacing.sm) {
                // All brands button
                FilterChip(
                    title: "All",
                    isSelected: selectedBrand == nil
                ) {
                    selectedBrand = nil
                }

                // Brand chips
                ForEach(catalogService.brands, id: \.self) { brand in
                    FilterChip(
                        title: brand,
                        isSelected: selectedBrand == brand
                    ) {
                        selectedBrand = selectedBrand == brand ? nil : brand
                    }
                }
            }
            .padding(.horizontal, BTSpacing.xs)
        }
    }

    // MARK: - Methods

    private func createBallProfile(fromCatalog ball: CatalogBall) {
        let suggestedColor = ball.suggestedHSVColor

        let profile = BallProfile(
            name: ball.name,
            brand: ball.brand,
            color: suggestedColor,
            colorTolerance: 15.0,
            markerColor: nil
        )

        let entity = BallProfileEntity(from: profile)
        entity.catalogBallId = ball.id

        modelContext.insert(entity)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save ball profile: \(error)")
        }
    }

    private func createBallProfile(from profile: BallProfile) {
        let entity = BallProfileEntity(from: profile)
        modelContext.insert(entity)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Failed to save ball profile: \(error)")
        }
    }
}

// MARK: - Ball Row View

private struct BallRowView: View {
    let ball: CatalogBall

    var body: some View {
        HStack(spacing: BTSpacing.md) {
            // Color preview
            colorPreview

            // Ball info
            VStack(alignment: .leading, spacing: BTSpacing.xxs) {
                Text(ball.name)
                    .font(BTFont.body())
                    .foregroundColor(.btTextPrimary)

                Text(ball.coverstock)
                    .font(BTFont.caption())
                    .foregroundColor(.btTextSecondary)

                HStack(spacing: BTSpacing.md) {
                    Text(ball.specsString)
                        .font(BTFont.caption())
                        .foregroundColor(.btTextMuted)

                    Text(ball.coreType.displayName)
                        .font(BTFont.labelSmall())
                        .foregroundColor(.btPrimary)
                        .padding(.horizontal, BTSpacing.xs)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.btPrimary.opacity(0.15))
                        )
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.btTextMuted)
        }
        .padding(.vertical, BTSpacing.xs)
    }

    private var colorPreview: some View {
        ZStack {
            // Primary color
            Circle()
                .fill(Color(ball.suggestedHSVColor.uiColor))
                .frame(width: 44, height: 44)

            // Secondary color half-circle (if exists)
            if let secondary = ball.secondaryColor {
                let secondaryHSV = ball.colorNameToHSV(secondary)
                Circle()
                    .fill(Color(secondaryHSV.uiColor))
                    .frame(width: 44, height: 44)
                    .clipShape(
                        HalfCircle()
                    )
            }

            // Border
            Circle()
                .stroke(Color.btSurfaceHighlight, lineWidth: 1)
                .frame(width: 44, height: 44)
        }
    }
}

// MARK: - CatalogBall Extension for Color Access

private extension CatalogBall {
    func colorNameToHSV(_ colorName: String) -> HSVColor {
        switch colorName.lowercased() {
        case "blue", "navy", "cobalt":
            return HSVColor(h: 210, s: 80, v: 70)
        case "red", "crimson", "scarlet":
            return HSVColor(h: 0, s: 85, v: 75)
        case "purple", "violet", "plum":
            return HSVColor(h: 280, s: 70, v: 60)
        case "orange", "tangerine":
            return HSVColor(h: 30, s: 90, v: 85)
        case "green", "emerald", "lime":
            return HSVColor(h: 120, s: 70, v: 60)
        case "pink", "magenta", "fuchsia":
            return HSVColor(h: 330, s: 60, v: 80)
        case "yellow", "gold":
            return HSVColor(h: 55, s: 85, v: 90)
        case "black", "onyx", "carbon":
            return HSVColor(h: 0, s: 0, v: 15)
        case "white", "pearl":
            return HSVColor(h: 0, s: 0, v: 95)
        case "silver", "gray", "grey":
            return HSVColor(h: 0, s: 0, v: 60)
        case "teal", "cyan", "aqua":
            return HSVColor(h: 180, s: 70, v: 70)
        case "bronze", "copper", "brown":
            return HSVColor(h: 30, s: 60, v: 50)
        case "burgundy", "maroon":
            return HSVColor(h: 345, s: 70, v: 50)
        default:
            return HSVColor(h: 0, s: 0, v: 50)
        }
    }
}

// MARK: - Half Circle Shape

private struct HalfCircle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(BTFont.labelSmall())
                .foregroundColor(isSelected ? .btTextInverse : .btTextSecondary)
                .padding(.horizontal, BTSpacing.md)
                .padding(.vertical, BTSpacing.sm)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.btPrimary : Color.btSurfaceElevated)
                )
        }
    }
}

// MARK: - Custom Ball Sheet

private struct CustomBallSheet: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (BallProfile) -> Void

    @State private var name = ""
    @State private var brand = ""
    @State private var selectedPreset: BallColorPreset = .blue

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Ball Name", text: $name)
                        .listRowBackground(Color.btSurface)

                    TextField("Brand (optional)", text: $brand)
                        .listRowBackground(Color.btSurface)
                } header: {
                    Text("Ball Info")
                        .font(BTFont.labelSmall())
                        .foregroundColor(.btTextMuted)
                }

                Section {
                    Picker("Primary Color", selection: $selectedPreset) {
                        ForEach(BallColorPreset.allCases, id: \.self) { preset in
                            HStack {
                                Circle()
                                    .fill(Color(preset.hsvColor.uiColor))
                                    .frame(width: 20, height: 20)
                                Text(preset.displayName)
                            }
                            .tag(preset)
                        }
                    }
                    .listRowBackground(Color.btSurface)

                    // Color preview
                    HStack {
                        Text("Preview")
                            .font(BTFont.body())
                            .foregroundColor(.btTextPrimary)

                        Spacer()

                        Circle()
                            .fill(Color(selectedPreset.hsvColor.uiColor))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Circle()
                                    .stroke(Color.btSurfaceHighlight, lineWidth: 1)
                            )
                    }
                    .listRowBackground(Color.btSurface)
                } header: {
                    Text("Color")
                        .font(BTFont.labelSmall())
                        .foregroundColor(.btTextMuted)
                } footer: {
                    Text("Choose the closest color to your ball for tracking accuracy.")
                        .font(BTFont.caption())
                        .foregroundColor(.btTextMuted)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.btBackground)
            .navigationTitle("Custom Ball")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.btPrimary)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveBall()
                    }
                    .foregroundColor(.btPrimary)
                    .disabled(name.isEmpty)
                }
            }
        }
    }

    private func saveBall() {
        let profile = BallProfile.preset(
            selectedPreset,
            name: name,
            brand: brand.isEmpty ? nil : brand
        )
        onSave(profile)
        dismiss()
    }
}

// MARK: - Preview

#Preview("Ball Picker") {
    BallPickerView()
        .modelContainer(for: [BallProfileEntity.self], inMemory: true)
}
