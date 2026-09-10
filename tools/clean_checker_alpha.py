#!/usr/bin/env python3
"""Convert a baked neutral checkerboard into real alpha without erasing ivory sprites."""

import argparse
from collections import deque
from pathlib import Path

from PIL import Image, ImageFilter


def is_background_candidate(pixel: tuple[int, int, int]) -> bool:
    red, green, blue = pixel
    chroma = max(pixel) - min(pixel)
    luminance = (red * 0.2126 + green * 0.7152 + blue * 0.0722) / 255.0
    # Generated checkerboards contain compression-like gray-blue noise and
    # shadows. The flood fill starts only at the canvas edge, so this broad
    # threshold can cross that noise without punching holes in enclosed ivory
    # faces or gloves.
    return chroma <= 38 and luminance >= 0.24


def clean_checker(source: Path, destination: Path) -> None:
    image = Image.open(source).convert("RGB")
    width, height = image.size
    pixels = image.load()
    outside = bytearray(width * height)
    queue: deque[tuple[int, int]] = deque()

    def enqueue(x: int, y: int) -> None:
        index = y * width + x
        if not outside[index] and is_background_candidate(pixels[x, y]):
            outside[index] = 1
            queue.append((x, y))

    for x in range(width):
        enqueue(x, 0)
        enqueue(x, height - 1)
    for y in range(height):
        enqueue(0, y)
        enqueue(width - 1, y)

    while queue:
        x, y = queue.popleft()
        if x > 0:
            enqueue(x - 1, y)
        if x + 1 < width:
            enqueue(x + 1, y)
        if y > 0:
            enqueue(x, y - 1)
        if y + 1 < height:
            enqueue(x, y + 1)

    rgba = image.convert("RGBA")
    output = rgba.load()
    removed = 0
    for y in range(height):
        for x in range(width):
            if outside[y * width + x]:
                output[x, y] = (0, 0, 0, 0)
                removed += 1

    # The generated checker can contain colored compression islands that are
    # not reachable by the neutral flood fill. Keep character-sized connected
    # components and discard tiny disconnected flecks.
    visited = bytearray(width * height)
    for y in range(height):
        for x in range(width):
            start_index = y * width + x
            if visited[start_index] or output[x, y][3] == 0:
                continue
            component: list[tuple[int, int]] = []
            component_queue = deque([(x, y)])
            visited[start_index] = 1
            while component_queue:
                current_x, current_y = component_queue.popleft()
                component.append((current_x, current_y))
                for neighbor_x, neighbor_y in (
                    (current_x - 1, current_y),
                    (current_x + 1, current_y),
                    (current_x, current_y - 1),
                    (current_x, current_y + 1),
                ):
                    if not (0 <= neighbor_x < width and 0 <= neighbor_y < height):
                        continue
                    neighbor_index = neighbor_y * width + neighbor_x
                    if visited[neighbor_index] or output[neighbor_x, neighbor_y][3] == 0:
                        continue
                    visited[neighbor_index] = 1
                    component_queue.append((neighbor_x, neighbor_y))
            if len(component) < 600:
                for component_x, component_y in component:
                    output[component_x, component_y] = (0, 0, 0, 0)
                removed += len(component)

    # A small morphological opening removes checker specks that touch an
    # anti-aliased edge. At master resolution the real costume contours are
    # much thicker than this filter and remain intact.
    alpha = rgba.getchannel("A")
    alpha = alpha.filter(ImageFilter.MinFilter(5)).filter(ImageFilter.MaxFilter(5))
    rgba.putalpha(alpha)

    destination.parent.mkdir(parents=True, exist_ok=True)
    rgba.save(destination, "PNG")
    print(f"{source} -> {destination}: removed {removed:,} background pixels")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()
    clean_checker(args.source, args.destination)


if __name__ == "__main__":
    main()
