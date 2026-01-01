//
//  BowlerTraxApp.swift
//  BowlerTrax
//
//  Created by BowlerTrax Team
//

import SwiftUI
import SwiftData

@main
struct BowlerTraxApp: App {
    // MARK: - Properties

    let modelContainer: ModelContainer

    // MARK: - Initialization

    init() {
        // Define the schema for all SwiftData entities
        let schema = Schema([
            SessionEntity.self,
            ShotEntity.self,
            BallProfileEntity.self,
            CalibrationEntity.self,
            CenterEntity.self,
            OilPatternEntity.self
        ])

        // Configure the model container
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Failed to create ModelContainer: \(error.localizedDescription)")
        }
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(modelContainer)
    }
}
