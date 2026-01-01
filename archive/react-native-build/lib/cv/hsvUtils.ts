/**
 * HSV Color Space Utilities
 * RGB to HSV conversion for robust color detection under varying lighting
 */

import { RGBColor, HSVColor } from '@/types';

/**
 * Convert RGB color to HSV color space
 * HSV is more robust to lighting changes than RGB
 */
export function rgbToHsv(rgb: RGBColor): HSVColor {
  const r = rgb.r / 255;
  const g = rgb.g / 255;
  const b = rgb.b / 255;

  const max = Math.max(r, g, b);
  const min = Math.min(r, g, b);
  const delta = max - min;

  let h = 0;
  let s = 0;
  const v = max;

  if (delta !== 0) {
    s = delta / max;

    if (max === r) {
      h = ((g - b) / delta) % 6;
    } else if (max === g) {
      h = (b - r) / delta + 2;
    } else {
      h = (r - g) / delta + 4;
    }

    h = Math.round(h * 60);
    if (h < 0) h += 360;
  }

  return {
    h,
    s: Math.round(s * 100),
    v: Math.round(v * 100),
  };
}

/**
 * Convert HSV color back to RGB
 */
export function hsvToRgb(hsv: HSVColor): RGBColor {
  const h = hsv.h;
  const s = hsv.s / 100;
  const v = hsv.v / 100;

  const c = v * s;
  const x = c * (1 - Math.abs(((h / 60) % 2) - 1));
  const m = v - c;

  let r = 0, g = 0, b = 0;

  if (h >= 0 && h < 60) {
    r = c; g = x; b = 0;
  } else if (h >= 60 && h < 120) {
    r = x; g = c; b = 0;
  } else if (h >= 120 && h < 180) {
    r = 0; g = c; b = x;
  } else if (h >= 180 && h < 240) {
    r = 0; g = x; b = c;
  } else if (h >= 240 && h < 300) {
    r = x; g = 0; b = c;
  } else {
    r = c; g = 0; b = x;
  }

  return {
    r: Math.round((r + m) * 255),
    g: Math.round((g + m) * 255),
    b: Math.round((b + m) * 255),
  };
}

/**
 * Check if a color is within tolerance of a target color in HSV space
 */
export function isColorMatch(
  color: HSVColor,
  target: HSVColor,
  tolerance: { h: number; s: number; v: number }
): boolean {
  // Handle hue wraparound (0 and 360 are the same)
  let hDiff = Math.abs(color.h - target.h);
  if (hDiff > 180) hDiff = 360 - hDiff;

  return (
    hDiff <= tolerance.h &&
    Math.abs(color.s - target.s) <= tolerance.s &&
    Math.abs(color.v - target.v) <= tolerance.v
  );
}

/**
 * Default color tolerance for ball detection
 * Tuned for bowling ball colors under lane lighting
 */
export const DEFAULT_COLOR_TOLERANCE = {
  h: 15,  // Hue tolerance (0-360)
  s: 30,  // Saturation tolerance (0-100)
  v: 30,  // Value/brightness tolerance (0-100)
};
