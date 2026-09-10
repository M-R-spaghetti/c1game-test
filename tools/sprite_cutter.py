#!/usr/bin/env python3
"""
Sprite Sheet Cutter & Processor for AI-Generated Game Assets.
Usage:
    python3 tools/sprite_cutter.py input.png --rows 4 --cols 4 --out assets/sprites/characters/player/
"""

import os
import sys
import argparse
from PIL import Image

def slice_spritesheet(input_path: str, rows: int, cols: int, output_dir: str, prefix: str = "frame"):
    os.makedirs(output_dir, exist_ok=True)
    img = Image.open(input_path).convert("RGBA")
    sheet_w, sheet_h = img.size
    cell_w = sheet_w // cols
    cell_h = sheet_h // rows

    print(f"Loaded sheet: {sheet_w}x{sheet_h} px | Cell size: {cell_w}x{cell_h} px ({cols}x{rows})")

    frame_idx = 0
    for r in range(rows):
        for c in range(cols):
            x = c * cell_w
            y = r * cell_h
            cell = img.crop((x, y, x + cell_w, y + cell_h))
            
            # Check if frame is not completely transparent/empty
            bbox = cell.getbbox()
            if bbox is not None:
                filename = f"{prefix}_{frame_idx:02d}.png"
                out_path = os.path.join(output_dir, filename)
                cell.save(out_path, "PNG")
                print(f"  Saved: {out_path}")
            else:
                print(f"  Skipped empty frame {frame_idx:02d}")
            frame_idx += 1

    print(f"Done! All extracted frames saved to: {output_dir}")

def main():
    parser = argparse.ArgumentParser(description="Slice a sprite sheet into individual frames.")
    parser.add_argument("input", help="Path to input sprite sheet PNG")
    parser.add_argument("--rows", "-r", type=int, default=4, help="Number of rows (default: 4)")
    parser.add_argument("--cols", "-c", type=int, default=4, help="Number of columns (default: 4)")
    parser.add_argument("--out", "-o", default="assets/sprites/extracted", help="Output directory")
    parser.add_argument("--prefix", "-p", default="frame", help="Prefix for frame files")
    args = parser.parse_args()

    slice_spritesheet(args.input, args.rows, args.cols, args.out, args.prefix)

if __name__ == "__main__":
    main()
