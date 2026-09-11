#!/usr/bin/env python3
"""Render 1024×1024 opaque Ebb onboarding app icon from SVG source."""

from pathlib import Path

import cairosvg

# Full-square soft-paper gradient + happy Ebb (~68% canvas). No inset well, no baked corners.
SVG = """<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024" viewBox="0 0 1024 1024">
  <defs>
    <linearGradient id="bg-grad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#FFFCFA"/>
      <stop offset="55%" stop-color="#F9EBE7"/>
      <stop offset="100%" stop-color="#F5E0E6"/>
    </linearGradient>
    <linearGradient id="ebb-grad" x1="34" y1="22" x2="86" y2="100" gradientUnits="userSpaceOnUse">
      <stop stop-color="#E8B8C4"/>
      <stop offset="1" stop-color="#C2607A"/>
    </linearGradient>
  </defs>
  <!-- Edge-to-edge soft paper gradient (135°) — opaque RGB -->
  <rect width="1024" height="1024" fill="url(#bg-grad)"/>
  <!-- Happy Ebb · ~68% of canvas (696 / 1024) · paths from EbbMascot.swift -->
  <g transform="translate(512 512) scale(5.8) translate(-60 -60)">
    <ellipse cx="60" cy="102" rx="30" ry="5" fill="#2A2622" opacity="0.05"/>
    <path d="M60 16C60 16 28 50 28 72c0 18.778 14.327 34 32 34s32-15.222 32-34C92 50 60 16 60 16Z" fill="url(#ebb-grad)"/>
    <circle cx="50" cy="60" r="3.3" fill="#2A2622" opacity="0.52"/>
    <circle cx="70" cy="60" r="3.3" fill="#2A2622" opacity="0.52"/>
    <path d="M52 72c3.5 4.2 12.5 4.2 16 0" stroke="#2A2622" stroke-width="2.2" stroke-linecap="round" opacity="0.4" fill="none"/>
    <circle cx="28" cy="34" r="2.4" fill="#A24D64" opacity="0.5"/>
    <circle cx="90" cy="30" r="2" fill="#D48A9A" opacity="0.65"/>
    <ellipse cx="44" cy="68" rx="3.6" ry="2.2" fill="#A24D64" opacity="0.28"/>
    <ellipse cx="76" cy="68" rx="3.6" ry="2.2" fill="#A24D64" opacity="0.28"/>
  </g>
</svg>
"""

OUT = Path(__file__).resolve().parents[1] / "Ebb/Ebb/Assets.xcassets/AppIcon.appiconset/icon-1024.png"
SVG_OUT = Path(__file__).resolve().parents[1] / "docs/ebb-app-icon-onboarding.svg"

if __name__ == "__main__":
    SVG_OUT.write_text(SVG, encoding="utf-8")
    cairosvg.svg2png(bytestring=SVG.encode("utf-8"), write_to=str(OUT), output_width=1024, output_height=1024)
    print(f"Wrote {OUT}")
