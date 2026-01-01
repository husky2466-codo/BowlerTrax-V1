//
//  LaneCanvas.swift
//  BowlerTrax
//
//  Top-down bowling lane canvas view with board lines, arrows, and pin deck
//

import SwiftUI

// MARK: - Lane Constants

/// USBC standard lane dimensions
enum LaneConstants {
    static let laneLength: Double = 60.0        // feet (foul line to head pin)
    static let laneWidth: Double = 41.5         // inches
    static let boardCount: Int = 39             // boards numbered 1-39
    static let boardWidth: Double = 1.0641      // inches per board

    static let arrowDistance: Double = 15.0     // feet from foul line
    static let arrowBoards = [5, 10, 15, 20, 25, 30, 35]  // board positions

    static let pocketBoardRight: Double = 17.5  // right-handed pocket
    static let pocketBoardLeft: Double = 22.5   // left-handed pocket

    static let optimalEntryAngle: Double = 6.0  // degrees for max strikes

    // Phase transition distances
    static let skidEndDistance: Double = 35.0   // feet - end of skid phase
    static let hookEndDistance: Double = 46.0   // feet - end of hook phase
    // Roll phase: 46-60 feet

    // Display board numbers
    static let displayBoards = [1, 5, 10, 15, 20, 25, 30, 35, 39]

    // Distance markers
    static let distanceMarkers: [Double] = [0, 15, 35, 46, 60]
}

// MARK: - LaneCanvas View

/// Top-down bowling lane canvas with board lines, arrows, and pin deck
struct LaneCanvas: View {
    // MARK: - Properties

    var showBoardNumbers: Bool = true
    var showArrows: Bool = true
    var showDistanceMarkers: Bool = true

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                drawLane(context: context, size: size)
            }
        }
        .aspectRatio(LaneConstants.laneLength / (LaneConstants.laneWidth / 12.0), contentMode: .fit)
    }

    // MARK: - Drawing Methods

    private func drawLane(context: GraphicsContext, size: CGSize) {
        let laneRect = CGRect(origin: .zero, size: size)

        // Draw lane background (dark wood)
        drawLaneBackground(context: context, rect: laneRect)

        // Draw board lines
        drawBoardLines(context: context, size: size)

        // Draw foul line at top
        drawFoulLine(context: context, size: size)

        // Draw arrows at 15 feet
        if showArrows {
            drawArrows(context: context, size: size)
        }

        // Draw pin deck at bottom
        drawPinDeck(context: context, size: size)

        // Draw board numbers at bottom
        if showBoardNumbers {
            drawBoardNumbers(context: context, size: size)
        }

        // Draw distance markers on left side
        if showDistanceMarkers {
            drawDistanceMarkers(context: context, size: size)
        }
    }

    private func drawLaneBackground(context: GraphicsContext, rect: CGRect) {
        let backgroundPath = Path(rect)
        context.fill(backgroundPath, with: .color(Color.btLaneWood))
    }

    private func drawBoardLines(context: GraphicsContext, size: CGSize) {
        let boardWidth = size.width / CGFloat(LaneConstants.boardCount)

        for i in 1..<LaneConstants.boardCount {
            let x = CGFloat(i) * boardWidth
            var path = Path()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))

            // Subtle board lines
            context.stroke(
                path,
                with: .color(Color.white.opacity(0.08)),
                lineWidth: 0.5
            )
        }
    }

    private func drawFoulLine(context: GraphicsContext, size: CGSize) {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: 2))
        path.addLine(to: CGPoint(x: size.width, y: 2))

        context.stroke(
            path,
            with: .color(Color.btError),
            lineWidth: 3
        )
    }

    private func drawArrows(context: GraphicsContext, size: CGSize) {
        let boardWidth = size.width / CGFloat(LaneConstants.boardCount)
        let arrowY = distanceToY(feet: LaneConstants.arrowDistance, height: size.height)
        let arrowSize: CGFloat = min(boardWidth * 0.8, 12)

        for board in LaneConstants.arrowBoards {
            let x = boardToX(board: Double(board), width: size.width)

            // Draw triangular arrow pointing down
            var arrowPath = Path()
            arrowPath.move(to: CGPoint(x: x, y: arrowY - arrowSize / 2))
            arrowPath.addLine(to: CGPoint(x: x - arrowSize / 2, y: arrowY + arrowSize / 2))
            arrowPath.addLine(to: CGPoint(x: x + arrowSize / 2, y: arrowY + arrowSize / 2))
            arrowPath.closeSubpath()

            // Fill with primary color
            context.fill(arrowPath, with: .color(Color.btPrimary.opacity(0.8)))

            // Stroke outline
            context.stroke(
                arrowPath,
                with: .color(Color.btPrimary),
                lineWidth: 1
            )
        }
    }

    private func drawPinDeck(context: GraphicsContext, size: CGSize) {
        let pinDeckY = size.height - 40
        let pinDeckHeight: CGFloat = 35
        let centerX = size.width / 2

        // Pin deck background
        let pinDeckRect = CGRect(
            x: size.width * 0.25,
            y: pinDeckY,
            width: size.width * 0.5,
            height: pinDeckHeight
        )
        let deckPath = Path(roundedRect: pinDeckRect, cornerRadius: 4)
        context.fill(deckPath, with: .color(Color.btSurface.opacity(0.6)))

        // Draw 10-pin triangle formation
        let pinRadius: CGFloat = 4
        let pinSpacing: CGFloat = 12

        // Pin positions relative to center (4-3-2-1 formation)
        let pinPositions: [(row: Int, offset: CGFloat)] = [
            // Row 1 (head pin) - 1 pin
            (0, 0),
            // Row 2 - 2 pins
            (1, -0.5), (1, 0.5),
            // Row 3 - 3 pins
            (2, -1), (2, 0), (2, 1),
            // Row 4 - 4 pins
            (3, -1.5), (3, -0.5), (3, 0.5), (3, 1.5)
        ]

        for (row, offset) in pinPositions {
            let x = centerX + offset * pinSpacing
            let y = pinDeckY + 8 + CGFloat(row) * pinSpacing * 0.7

            let pinPath = Path(ellipseIn: CGRect(
                x: x - pinRadius,
                y: y - pinRadius,
                width: pinRadius * 2,
                height: pinRadius * 2
            ))

            context.fill(pinPath, with: .color(Color.btTextPrimary))
        }
    }

    private func drawBoardNumbers(context: GraphicsContext, size: CGSize) {
        let y = size.height - 8

        for board in LaneConstants.displayBoards {
            let x = boardToX(board: Double(board), width: size.width)

            let text = Text("\(board)")
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(Color.btTextMuted)

            context.draw(
                context.resolve(text),
                at: CGPoint(x: x, y: y),
                anchor: .center
            )
        }
    }

    private func drawDistanceMarkers(context: GraphicsContext, size: CGSize) {
        let x: CGFloat = 12

        for distance in LaneConstants.distanceMarkers {
            let y = distanceToY(feet: distance, height: size.height)

            let text = Text("\(Int(distance))ft")
                .font(.system(size: 7, weight: .regular))
                .foregroundColor(Color.btTextMuted)

            context.draw(
                context.resolve(text),
                at: CGPoint(x: x, y: y),
                anchor: .leading
            )

            // Draw subtle horizontal line
            if distance > 0 && distance < 60 {
                var linePath = Path()
                linePath.move(to: CGPoint(x: 30, y: y))
                linePath.addLine(to: CGPoint(x: size.width - 10, y: y))

                context.stroke(
                    linePath,
                    with: .color(Color.white.opacity(0.05)),
                    style: StrokeStyle(lineWidth: 0.5, dash: [4, 4])
                )
            }
        }
    }

    // MARK: - Coordinate Helpers

    /// Convert board number (1-39) to X coordinate
    private func boardToX(board: Double, width: CGFloat) -> CGFloat {
        let boardWidth = width / CGFloat(LaneConstants.boardCount)
        return CGFloat(board - 0.5) * boardWidth
    }

    /// Convert distance in feet (0-60) to Y coordinate
    private func distanceToY(feet: Double, height: CGFloat) -> CGFloat {
        let normalizedY = feet / LaneConstants.laneLength
        return CGFloat(normalizedY) * height
    }
}

// MARK: - Preview

#Preview("Lane Canvas - Full") {
    LaneCanvas(
        showBoardNumbers: true,
        showArrows: true,
        showDistanceMarkers: true
    )
    .frame(height: 600)
    .padding()
    .background(Color.btBackground)
}

#Preview("Lane Canvas - Minimal") {
    LaneCanvas(
        showBoardNumbers: false,
        showArrows: true,
        showDistanceMarkers: false
    )
    .frame(height: 400)
    .padding()
    .background(Color.btBackground)
}
