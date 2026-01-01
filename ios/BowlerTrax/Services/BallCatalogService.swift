//
//  BallCatalogService.swift
//  BowlerTrax
//
//  Service for loading and managing the bowling ball catalog
//

import Foundation

// MARK: - Ball Catalog Error

enum BallCatalogError: LocalizedError {
    case fileNotFound
    case invalidData
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "Ball catalog file not found."
        case .invalidData:
            return "Ball catalog data is invalid."
        case .decodingFailed(let error):
            return "Failed to decode ball catalog: \(error.localizedDescription)"
        }
    }
}

// MARK: - Ball Catalog Service

/// Service for loading and querying the bowling ball catalog
@MainActor
final class BallCatalogService: ObservableObject {
    // MARK: - Singleton

    static let shared = BallCatalogService()

    // MARK: - Published Properties

    @Published private(set) var catalog: BallCatalog?
    @Published private(set) var isLoading = false
    @Published private(set) var error: BallCatalogError?

    // MARK: - Private Properties

    private var cachedBalls: [CatalogBall]?
    private var cachedBrands: [String]?

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Load the ball catalog from the bundled JSON file
    func loadCatalog() async {
        guard catalog == nil else { return }  // Already loaded

        isLoading = true
        error = nil

        do {
            let loadedCatalog = try await loadFromBundle()
            catalog = loadedCatalog
            cachedBalls = loadedCatalog.balls
            cachedBrands = loadedCatalog.brands
        } catch let catalogError as BallCatalogError {
            error = catalogError
        } catch {
            self.error = .decodingFailed(error)
        }

        isLoading = false
    }

    /// Get all balls, loading if necessary
    var balls: [CatalogBall] {
        cachedBalls ?? []
    }

    /// Get all brands, loading if necessary
    var brands: [String] {
        cachedBrands ?? []
    }

    /// Get balls for a specific brand
    func balls(forBrand brand: String) -> [CatalogBall] {
        guard let catalog = catalog else { return [] }
        return catalog.balls(forBrand: brand)
    }

    /// Search balls by query
    func search(query: String) -> [CatalogBall] {
        guard let catalog = catalog else { return [] }
        return catalog.search(query: query)
    }

    /// Search with brand filter
    func search(query: String, brand: String?) -> [CatalogBall] {
        var results: [CatalogBall]

        if let brand = brand, !brand.isEmpty {
            results = balls(forBrand: brand)
        } else {
            results = balls
        }

        if query.isEmpty {
            return results
        }

        let lowercasedQuery = query.lowercased()
        return results.filter { ball in
            ball.name.lowercased().contains(lowercasedQuery) ||
            ball.brand.lowercased().contains(lowercasedQuery) ||
            ball.coverstock.lowercased().contains(lowercasedQuery)
        }
    }

    /// Get a ball by ID
    func ball(withId id: String) -> CatalogBall? {
        catalog?.ball(withId: id)
    }

    /// Get balls filtered by color
    func balls(withColor color: String) -> [CatalogBall] {
        guard let catalog = catalog else { return [] }
        return catalog.balls(withColor: color)
    }

    /// Get balls grouped by brand (sorted)
    var ballsByBrand: [(brand: String, balls: [CatalogBall])] {
        guard let catalog = catalog else { return [] }

        return catalog.brands.map { brand in
            (brand: brand, balls: catalog.balls(forBrand: brand).sorted { $0.name < $1.name })
        }
    }

    /// Reload the catalog (for refresh purposes)
    func reload() async {
        catalog = nil
        cachedBalls = nil
        cachedBrands = nil
        await loadCatalog()
    }

    // MARK: - Private Methods

    private func loadFromBundle() async throws -> BallCatalog {
        guard let url = Bundle.main.url(forResource: "BallDatabase", withExtension: "json") else {
            throw BallCatalogError.fileNotFound
        }

        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw BallCatalogError.invalidData
        }

        let decoder = JSONDecoder()
        do {
            return try decoder.decode(BallCatalog.self, from: data)
        } catch {
            throw BallCatalogError.decodingFailed(error)
        }
    }
}

// MARK: - Preview Helper

extension BallCatalogService {
    /// Create a service with sample data for previews
    static func preview() -> BallCatalogService {
        let service = BallCatalogService()
        service.catalog = BallCatalog.sampleCatalog
        service.cachedBalls = BallCatalog.sampleCatalog.balls
        service.cachedBrands = BallCatalog.sampleCatalog.brands
        return service
    }
}

// MARK: - Sample Data

extension BallCatalog {
    /// Sample catalog for previews and testing
    static var sampleCatalog: BallCatalog {
        BallCatalog(
            balls: [
                CatalogBall(
                    id: "storm-phaze-4",
                    name: "Phaze 4",
                    brand: "Storm",
                    coverstock: "R3S Pearl Reactive",
                    coreName: "Velocity",
                    coreType: .asymmetric,
                    rg: 2.48,
                    differential: 0.051,
                    massBiasDiff: 0.013,
                    releaseDate: "2023-09",
                    colors: ["purple", "blue"]
                ),
                CatalogBall(
                    id: "storm-hyroad",
                    name: "Hy-Road",
                    brand: "Storm",
                    coverstock: "R2S Pearl Reactive",
                    coreName: "Inverted Fe2",
                    coreType: .symmetric,
                    rg: 2.48,
                    differential: 0.048,
                    massBiasDiff: nil,
                    releaseDate: "2008-06",
                    colors: ["blue", "purple"]
                ),
                CatalogBall(
                    id: "brunswick-rhino",
                    name: "Rhino",
                    brand: "Brunswick",
                    coverstock: "R-16 Reactive",
                    coreName: "Light Bulb",
                    coreType: .symmetric,
                    rg: 2.54,
                    differential: 0.022,
                    massBiasDiff: nil,
                    releaseDate: "2020-01",
                    colors: ["blue", "black"]
                ),
                CatalogBall(
                    id: "hammer-black-widow",
                    name: "Black Widow 2.0",
                    brand: "Hammer",
                    coverstock: "Aggression CFI",
                    coreName: "Gas Mask",
                    coreType: .symmetric,
                    rg: 2.50,
                    differential: 0.052,
                    massBiasDiff: nil,
                    releaseDate: "2022-05",
                    colors: ["black", "red"]
                ),
                CatalogBall(
                    id: "motiv-venom-shock",
                    name: "Venom Shock",
                    brand: "Motiv",
                    coverstock: "Turmoil MFS Reactive",
                    coreName: "Gear",
                    coreType: .symmetric,
                    rg: 2.50,
                    differential: 0.037,
                    massBiasDiff: nil,
                    releaseDate: "2015-03",
                    colors: ["orange", "purple"]
                )
            ],
            lastUpdated: "2025-01-01"
        )
    }
}
