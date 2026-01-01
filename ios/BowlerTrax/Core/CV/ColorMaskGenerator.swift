//
//  ColorMaskGenerator.swift
//  BowlerTrax
//
//  HSV color masking for bowling ball detection.
//  Uses Core Image filters for GPU-accelerated color space conversion and thresholding.
//

import CoreImage
import CoreVideo
import UIKit

// MARK: - Color Tolerance Configuration

/// Configuration for color matching tolerance
struct ColorTolerance: Sendable {
    var hueTolerance: Double      // +/- degrees (default 15)
    var saturationTolerance: Double // +/- normalized (default 0.2)
    var valueTolerance: Double    // +/- normalized (default 0.3)

    static let `default` = ColorTolerance(
        hueTolerance: 15.0,
        saturationTolerance: 0.2,
        valueTolerance: 0.3
    )

    /// Tighter tolerance for well-lit conditions
    static let tight = ColorTolerance(
        hueTolerance: 10.0,
        saturationTolerance: 0.15,
        valueTolerance: 0.2
    )

    /// Looser tolerance for variable lighting
    static let loose = ColorTolerance(
        hueTolerance: 20.0,
        saturationTolerance: 0.25,
        valueTolerance: 0.4
    )
}

// MARK: - Color Mask Generator

/// Generates binary masks from frames based on target HSV color
final class ColorMaskGenerator: @unchecked Sendable {
    // MARK: - Properties

    private let ciContext: CIContext
    private var targetColor: HSVColor
    private var tolerance: ColorTolerance

    // Core Image kernel for color masking
    private let colorMaskKernel: CIColorKernel?

    // Morphology parameters
    private let erodeRadius: Double = 2.0
    private let dilateRadius: Double = 3.0

    // MARK: - Initialization

    init(
        targetColor: HSVColor,
        tolerance: ColorTolerance = .default
    ) {
        self.targetColor = targetColor
        self.tolerance = tolerance

        // Create Metal-accelerated CIContext
        if let device = MTLCreateSystemDefaultDevice() {
            self.ciContext = CIContext(
                mtlDevice: device,
                options: [
                    .useSoftwareRenderer: false,
                    .priorityRequestLow: false
                ]
            )
        } else {
            self.ciContext = CIContext()
        }

        // Create color mask kernel
        self.colorMaskKernel = Self.createColorMaskKernel()
    }

    // MARK: - Public Methods

    /// Update target color for detection
    func updateTargetColor(_ color: HSVColor) {
        self.targetColor = color
    }

    /// Update tolerance settings
    func updateTolerance(_ tolerance: ColorTolerance) {
        self.tolerance = tolerance
    }

    /// Generate binary mask from pixel buffer
    /// - Parameters:
    ///   - pixelBuffer: Input frame in BGRA format
    /// - Returns: Binary CIImage mask (white = target color, black = background)
    func generateMask(from pixelBuffer: CVPixelBuffer) -> CIImage? {
        let inputImage = CIImage(cvPixelBuffer: pixelBuffer)
        return generateMask(from: inputImage)
    }

    /// Generate binary mask from CIImage
    /// - Parameters:
    ///   - inputImage: Input image
    /// - Returns: Binary CIImage mask (white = target color, black = background)
    func generateMask(from inputImage: CIImage) -> CIImage? {
        // Step 1: Create color threshold mask
        guard let rawMask = applyColorThreshold(to: inputImage) else {
            return nil
        }

        // Step 2: Apply morphological operations to clean the mask
        let cleanMask = applyMorphology(to: rawMask)

        return cleanMask
    }

    /// Generate cleaned binary mask with morphological operations
    /// - Parameters:
    ///   - pixelBuffer: Input frame
    /// - Returns: Cleaned binary mask
    func generateCleanedMask(from pixelBuffer: CVPixelBuffer) -> CIImage? {
        guard let rawMask = generateMask(from: pixelBuffer) else {
            return nil
        }
        return applyMorphologicalCleaning(to: rawMask)
    }

    /// Render mask to pixel buffer for processing
    /// - Parameters:
    ///   - mask: Binary mask image
    ///   - outputBuffer: Destination pixel buffer
    func renderMask(_ mask: CIImage, to outputBuffer: CVPixelBuffer) {
        ciContext.render(
            mask,
            to: outputBuffer,
            bounds: mask.extent,
            colorSpace: CGColorSpaceCreateDeviceGray()
        )
    }

    // MARK: - Private Methods

    /// Apply HSV color threshold to create binary mask
    private func applyColorThreshold(to image: CIImage) -> CIImage? {
        // Normalize HSV values for kernel (0-1 range)
        let targetH = targetColor.h / 360.0
        let targetS = targetColor.s / 100.0
        let targetV = targetColor.v / 100.0

        let tolH = tolerance.hueTolerance / 360.0
        let tolS = tolerance.saturationTolerance
        let tolV = tolerance.valueTolerance

        // If kernel is available, use it for GPU acceleration
        if let kernel = colorMaskKernel {
            return kernel.apply(
                extent: image.extent,
                arguments: [
                    image,
                    targetH,
                    targetS,
                    targetV,
                    tolH,
                    tolS,
                    tolV
                ]
            )
        }

        // Fallback: Use Core Image filter chain
        return applyColorThresholdFallback(to: image)
    }

    /// Fallback color threshold using standard Core Image filters
    private func applyColorThresholdFallback(to image: CIImage) -> CIImage? {
        // This is a simplified approach using color cube
        // Less accurate but works on all devices

        // Convert target HSV to RGB for comparison
        let targetUIColor = targetColor.uiColor
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        targetUIColor.getRed(&r, green: &g, blue: &b, alpha: nil)

        // Create a color matrix to highlight target color
        // This is an approximation - the kernel is more accurate
        let colorMatrix = CIFilter(name: "CIColorMatrix")
        colorMatrix?.setValue(image, forKey: kCIInputImageKey)

        // Adjust to emphasize target color
        let rVector = CIVector(x: 1 - r, y: 0, z: 0, w: 0)
        let gVector = CIVector(x: 0, y: 1 - g, z: 0, w: 0)
        let bVector = CIVector(x: 0, y: 0, z: 1 - b, w: 0)
        let aVector = CIVector(x: 0, y: 0, z: 0, w: 1)

        colorMatrix?.setValue(rVector, forKey: "inputRVector")
        colorMatrix?.setValue(gVector, forKey: "inputGVector")
        colorMatrix?.setValue(bVector, forKey: "inputBVector")
        colorMatrix?.setValue(aVector, forKey: "inputAVector")

        guard let adjusted = colorMatrix?.outputImage else {
            return nil
        }

        // Convert to grayscale and threshold
        let grayscale = adjusted.applyingFilter("CIPhotoEffectMono")

        // Apply threshold to create binary mask
        return grayscale.applyingFilter(
            "CIColorClamp",
            parameters: [
                "inputMinComponents": CIVector(x: 0.5, y: 0.5, z: 0.5, w: 1),
                "inputMaxComponents": CIVector(x: 1, y: 1, z: 1, w: 1)
            ]
        )
    }

    /// Apply morphological operations: erode to remove noise, dilate to restore shape
    private func applyMorphology(to mask: CIImage) -> CIImage {
        // Erosion: removes small noise spots
        let eroded = mask.applyingFilter(
            "CIMorphologyMinimum",
            parameters: ["inputRadius": erodeRadius]
        )

        // Dilation: restores ball shape, fills small gaps
        let dilated = eroded.applyingFilter(
            "CIMorphologyMaximum",
            parameters: ["inputRadius": dilateRadius]
        )

        return dilated
    }

    /// Apply opening followed by closing for better noise removal
    private func applyMorphologicalCleaning(to mask: CIImage) -> CIImage {
        // Opening: Erosion -> Dilation (removes noise)
        let opened = mask
            .applyingFilter("CIMorphologyMinimum", parameters: ["inputRadius": erodeRadius])
            .applyingFilter("CIMorphologyMaximum", parameters: ["inputRadius": erodeRadius])

        // Closing: Dilation -> Erosion (fills holes)
        let closed = opened
            .applyingFilter("CIMorphologyMaximum", parameters: ["inputRadius": dilateRadius])
            .applyingFilter("CIMorphologyMinimum", parameters: ["inputRadius": dilateRadius])

        return closed
    }

    // MARK: - Kernel Creation

    /// Create CIColorKernel for HSV-based color masking
    private static func createColorMaskKernel() -> CIColorKernel? {
        // Metal shader for RGB to HSV conversion and threshold
        let kernelSource = """
        kernel vec4 colorMask(__sample pixel,
                              float targetH, float targetS, float targetV,
                              float tolH, float tolS, float tolV) {
            // Convert RGB to HSV
            float r = pixel.r;
            float g = pixel.g;
            float b = pixel.b;

            float maxVal = max(r, max(g, b));
            float minVal = min(r, min(g, b));
            float delta = maxVal - minVal;

            float h = 0.0;
            float s = (maxVal == 0.0) ? 0.0 : delta / maxVal;
            float v = maxVal;

            if (delta != 0.0) {
                if (maxVal == r) {
                    h = (g - b) / delta;
                    if (h < 0.0) h += 6.0;
                } else if (maxVal == g) {
                    h = ((b - r) / delta) + 2.0;
                } else {
                    h = ((r - g) / delta) + 4.0;
                }
                h /= 6.0;  // Normalize to 0-1
            }

            // Check if within tolerance (hue is circular)
            float hueDiff = abs(h - targetH);
            if (hueDiff > 0.5) hueDiff = 1.0 - hueDiff;

            bool hueMatch = hueDiff <= tolH;
            bool satMatch = abs(s - targetS) <= tolS;
            bool valMatch = abs(v - targetV) <= tolV;

            if (hueMatch && satMatch && valMatch) {
                return vec4(1.0, 1.0, 1.0, 1.0);  // White = ball detected
            } else {
                return vec4(0.0, 0.0, 0.0, 1.0);  // Black = background
            }
        }
        """

        return CIColorKernel(source: kernelSource)
    }
}

// MARK: - Color Space Conversion Utilities

extension ColorMaskGenerator {
    /// Convert RGB values to HSV
    /// - Parameters:
    ///   - r: Red (0-1)
    ///   - g: Green (0-1)
    ///   - b: Blue (0-1)
    /// - Returns: HSVColor with h (0-360), s (0-100), v (0-100)
    static func rgbToHSV(r: Double, g: Double, b: Double) -> HSVColor {
        let maxVal = max(r, max(g, b))
        let minVal = min(r, min(g, b))
        let delta = maxVal - minVal

        // Calculate Value
        let v = maxVal * 100

        // Calculate Saturation
        let s: Double
        if maxVal == 0 {
            s = 0
        } else {
            s = (delta / maxVal) * 100
        }

        // Calculate Hue
        var h: Double = 0
        if delta != 0 {
            if maxVal == r {
                h = 60 * (((g - b) / delta).truncatingRemainder(dividingBy: 6))
            } else if maxVal == g {
                h = 60 * (((b - r) / delta) + 2)
            } else {
                h = 60 * (((r - g) / delta) + 4)
            }
        }
        if h < 0 { h += 360 }

        return HSVColor(h: h, s: s, v: v)
    }

    /// Convert HSV to RGB
    /// - Parameter hsv: HSVColor
    /// - Returns: Tuple of (r, g, b) each 0-1
    static func hsvToRGB(_ hsv: HSVColor) -> (r: Double, g: Double, b: Double) {
        let h = hsv.h / 60.0
        let s = hsv.s / 100.0
        let v = hsv.v / 100.0

        let c = v * s
        let x = c * (1 - abs(h.truncatingRemainder(dividingBy: 2) - 1))
        let m = v - c

        var r, g, b: Double

        switch Int(h) {
        case 0:
            (r, g, b) = (c, x, 0)
        case 1:
            (r, g, b) = (x, c, 0)
        case 2:
            (r, g, b) = (0, c, x)
        case 3:
            (r, g, b) = (0, x, c)
        case 4:
            (r, g, b) = (x, 0, c)
        default:
            (r, g, b) = (c, 0, x)
        }

        return (r + m, g + m, b + m)
    }
}

// MARK: - Predefined Ball Colors

extension ColorMaskGenerator {
    /// Common bowling ball colors with optimized HSV values
    enum BallColorPreset: CaseIterable {
        case blue
        case red
        case purple
        case orange
        case green
        case yellow
        case pink
        case black
        case white

        var hsvColor: HSVColor {
            switch self {
            case .blue:
                return HSVColor(h: 220, s: 80, v: 80)
            case .red:
                return HSVColor(h: 0, s: 85, v: 75)
            case .purple:
                return HSVColor(h: 280, s: 70, v: 70)
            case .orange:
                return HSVColor(h: 30, s: 90, v: 85)
            case .green:
                return HSVColor(h: 120, s: 75, v: 70)
            case .yellow:
                return HSVColor(h: 55, s: 85, v: 90)
            case .pink:
                return HSVColor(h: 330, s: 60, v: 85)
            case .black:
                return HSVColor(h: 0, s: 0, v: 15)
            case .white:
                return HSVColor(h: 0, s: 0, v: 95)
            }
        }

        var recommendedTolerance: ColorTolerance {
            switch self {
            case .black, .white:
                // Low saturation colors need different tolerance
                return ColorTolerance(
                    hueTolerance: 180.0, // Any hue
                    saturationTolerance: 0.15,
                    valueTolerance: 0.2
                )
            case .red, .orange:
                // Colors near hue wraparound need wider tolerance
                return ColorTolerance(
                    hueTolerance: 20.0,
                    saturationTolerance: 0.2,
                    valueTolerance: 0.3
                )
            default:
                return .default
            }
        }
    }
}
