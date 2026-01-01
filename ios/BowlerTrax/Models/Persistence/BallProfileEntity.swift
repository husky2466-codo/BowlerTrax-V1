//
//  BallProfileEntity.swift
//  BowlerTrax
//
//  SwiftData entity for ball profiles
//

import Foundation
import SwiftData
import UIKit

@Model
final class BallProfileEntity {
    @Attribute(.unique) var id: UUID
    var name: String
    var brand: String?
    var colorH: Double
    var colorS: Double
    var colorV: Double
    var colorTolerance: Double
    var markerColorH: Double?
    var markerColorS: Double?
    var markerColorV: Double?
    var createdAt: Date

    /// Optional link to a catalog ball (if selected from catalog)
    var catalogBallId: String?

    @Relationship(deleteRule: .nullify, inverse: \SessionEntity.ballProfile)
    var sessions: [SessionEntity]?

    /// Default initializer required by SwiftData
    init() {
        self.id = UUID()
        self.name = ""
        self.colorH = 0
        self.colorS = 0
        self.colorV = 100
        self.colorTolerance = 15.0
        self.createdAt = Date()
        self.catalogBallId = nil
    }

    init(from profile: BallProfile) {
        self.id = profile.id
        self.name = profile.name
        self.brand = profile.brand
        self.colorH = profile.color.h
        self.colorS = profile.color.s
        self.colorV = profile.color.v
        self.colorTolerance = profile.colorTolerance
        self.markerColorH = profile.markerColor?.h
        self.markerColorS = profile.markerColor?.s
        self.markerColorV = profile.markerColor?.v
        self.createdAt = profile.createdAt
        self.catalogBallId = nil
    }

    func toModel() -> BallProfile {
        var markerColor: HSVColor? = nil
        if let h = markerColorH, let s = markerColorS, let v = markerColorV {
            markerColor = HSVColor(h: h, s: s, v: v)
        }
        return BallProfile(
            id: id,
            name: name,
            brand: brand,
            color: HSVColor(h: colorH, s: colorS, v: colorV),
            colorTolerance: colorTolerance,
            markerColor: markerColor,
            createdAt: createdAt
        )
    }

    /// Update entity from domain model
    func update(from profile: BallProfile) {
        self.name = profile.name
        self.brand = profile.brand
        self.colorH = profile.color.h
        self.colorS = profile.color.s
        self.colorV = profile.color.v
        self.colorTolerance = profile.colorTolerance
        self.markerColorH = profile.markerColor?.h
        self.markerColorS = profile.markerColor?.s
        self.markerColorV = profile.markerColor?.v
    }

    /// Check if this ball was selected from the catalog
    var isFromCatalog: Bool {
        catalogBallId != nil
    }

    /// Get the display name including brand if available
    var displayName: String {
        if let brand = brand, !brand.isEmpty {
            return "\(brand) \(name)"
        }
        return name
    }

    /// Get the ball color as UIColor for display
    var uiColor: UIColor {
        UIColor(
            hue: CGFloat(colorH / 360.0),
            saturation: CGFloat(colorS / 100.0),
            brightness: CGFloat(colorV / 100.0),
            alpha: 1.0
        )
    }
}

// MARK: - Catalog Ball Integration

extension BallProfileEntity {
    /// Create from a catalog ball with suggested HSV color
    /// - Parameters:
    ///   - catalogId: The catalog ball ID
    ///   - name: Ball name
    ///   - brand: Ball brand
    ///   - suggestedColor: Suggested HSV color for tracking
    convenience init(
        fromCatalogId catalogId: String,
        name: String,
        brand: String,
        suggestedColor: HSVColor
    ) {
        self.init()
        self.id = UUID()
        self.name = name
        self.brand = brand
        self.catalogBallId = catalogId
        self.createdAt = Date()

        // Use the suggested color
        self.colorH = suggestedColor.h
        self.colorS = suggestedColor.s
        self.colorV = suggestedColor.v
        self.colorTolerance = 15.0
    }
}
