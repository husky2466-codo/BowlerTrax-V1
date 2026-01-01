//
//  DataSchema.swift
//  BowlerTrax
//
//  SwiftData schema configuration and model container setup
//

import Foundation
import SwiftData

// MARK: - SwiftData Configuration

enum DataSchema {
    static let models: [any PersistentModel.Type] = [
        CenterEntity.self,
        BallProfileEntity.self,
        CalibrationEntity.self,
        SessionEntity.self,
        ShotEntity.self,
        OilPatternEntity.self
    ]

    static var container: ModelContainer {
        let schema = Schema(models)
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    /// Create an in-memory container for previews and testing
    static var previewContainer: ModelContainer {
        let schema = Schema(models)
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            allowsSave: true
        )

        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create preview ModelContainer: \(error)")
        }
    }
}

// MARK: - Version History

/// Version history for migrations
enum DataSchemaVersion: Int {
    case v1 = 1  // Initial schema
    case v2 = 2  // Future: Add new fields

    static let current = DataSchemaVersion.v1
}

// MARK: - Migration Strategy

/// Migration plan (for future use)
struct DataMigrationPlan: SchemaMigrationPlan {
    static var schemas: [VersionedSchema.Type] {
        [SchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []  // No migrations yet
    }
}

/// Initial schema version
enum SchemaV1: VersionedSchema {
    static var versionIdentifier: Schema.Version {
        Schema.Version(1, 0, 0)
    }

    static var models: [any PersistentModel.Type] {
        DataSchema.models
    }
}

// MARK: - Model Container Extension

// Note: ModelContainer already provides mainContext property.
// No extension needed - use container.mainContext directly.
