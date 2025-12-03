"""
Convert an image to bytes for the Cody computer.

Since the Cody computer uses a dynamic color palette, the precise colors of \
the image are not yet defined.
The colors in the image file are interpreted by the arguments --color-0/1/2/3.
The image size must be 12x21 for sprites and 4x8 for characters.
You can either generate Cody BASIC code or Tass assembly.

By: Simon Romanowski
"""

import argparse
from collections.abc import Iterable
from pathlib import Path
import re
import sys
from typing import Literal

try:
    from PIL import Image
except ImportError:
    print(
        "ERROR: pillow library must be installed.\npython -m pip install pillow",
        file=sys.stderr,
    )
    raise SystemExit(1)


def _batched(it: Iterable, size: int) -> Iterable[Iterable]:
    collector = []
    for x in it:
        collector.append(x)
        if len(collector) == size:
            yield tuple(collector)
            collector = []
    if collector:
        yield tuple(collector)


def _rgb_to_hex(rgb: tuple[int, int, int]) -> str:
    value = (rgb[0] << 16) + (rgb[1] << 8) + rgb[2]
    return f"#{value:06X}"


def _hex_to_rgb(hex_str: str) -> tuple[int, int, int]:
    hex_str = hex_str.lstrip("#")  # '#' is optional
    if not re.match(r"^[0-9A-Fa-f]{6}$", hex_str):
        raise TypeError(f"{hex_str!r} is not a valid color literal")
    return tuple(int("".join(chars), 16) for chars in _batched(hex_str, 2))


def main():
    parser = argparse.ArgumentParser(
        description=__doc__.strip(),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    parser.add_argument(
        "file", type=Path, help="Path to the image file to convert."
    )
    parser.add_argument(
        "-s",
        "--sprite",
        action="store_true",
        help="Generate data for a sprite.",
    )
    parser.add_argument(
        "-c",
        "--character",
        action="store_true",
        help="Generate data for a character.",
    )
    parser.add_argument(
        "-l",
        "--language",
        choices=("tass", "basic"),
        help=(
            "The language for which code is generated. "
            "Choices are: %(choices)s."
        ),
        default="basic",
    )
    parser.add_argument(
        "--color-0",
        type=_hex_to_rgb,
        metavar="COLOR",
        help=(
            "Color in hex format that is used in the file to represent "
            "color 0. "
            "For characters, this is the first unique color. "
            "For sprites, this is the transparent color. "
            "Default is #FF0000 (red) for characters and "
            "#FFFFFF (white) for sprites."
        ),
    )
    parser.add_argument(
        "--color-1",
        type=_hex_to_rgb,
        metavar="COLOR",
        help=(
            "Color in hex format that is used in the file to represent "
            "color 1. "
            "For characters, this is the second unique color. "
            "For sprites, this is the first unique color. "
            "Default is #0000FF (blue) for characters and "
            "#FF0000 (red) for sprites."
        ),
    )
    parser.add_argument(
        "--color-2",
        type=_hex_to_rgb,
        metavar="COLOR",
        help=(
            "Color in hex format that is used in the file to represent "
            "color 2. "
            "For characters, this is the first shared color. "
            "For sprites, this is the second unique color. "
            "Default is #FFFFFF (white) for characters and "
            "#0000FF (blue) for sprites."
        ),
    )
    parser.add_argument(
        "--color-3",
        type=_hex_to_rgb,
        metavar="COLOR",
        help=(
            "Color in hex format that is used in the file to represent "
            "color 0. "
            "For characters, this is the second shared color. "
            "For sprites, this is the shared color. "
            "Default is #000000 (black) for characters and sprites."
        ),
    )
    parser.add_argument(
        "--line-number",
        type=int,
        help="Start line number for the generated BASIC lines.",
    )
    parser.add_argument(
        "--line-increment",
        type=int,
        default=10,
        help=(
            "Line number increment for generated BASIC lines. "
            "Default is %(default)s."
        ),
    )

    args = parser.parse_args()
    file: Path = args.file
    is_sprite: bool = args.sprite
    is_character: bool = args.character
    language: Literal["tass", "basic"] = args.language
    col0: tuple[int, int, int] | None = args.color_0
    col1: tuple[int, int, int] | None = args.color_1
    col2: tuple[int, int, int] | None = args.color_2
    col3: tuple[int, int, int] | None = args.color_3
    line_number_arg: int | None = args.line_number
    line_increment: int = args.line_increment

    if is_sprite == is_character:
        print("ERROR: Either -s or -c must be set!", file=sys.stderr)
        raise SystemExit(1)

    if col0 is None:
        col0 = (255, 0, 0) if is_character else (255, 255, 255)
    if col1 is None:
        col1 = (0, 0, 255) if is_character else (255, 0, 0)
    if col2 is None:
        col2 = (255, 255, 255) if is_character else (0, 0, 255)
    if col3 is None:
        col3 = (0, 0, 0)

    color_set = {col0, col1, col2, col3}
    if len(color_set) != 4:
        print(
            "ERROR: Color definitions must include 4 distinct colors! Found:",
            ", ".join(map(_rgb_to_hex, color_set)),
            file=sys.stderr,
        )
        raise SystemExit(1)

    img = Image.open(file).convert("RGB")

    image_size = (12, 21) if is_sprite else (4, 8)
    if img.size != image_size:
        image_type = "Sprite" if is_sprite else "Character"
        print(
            "ERROR:",
            image_type,
            "must be",
            image_size[0],
            "pixels wide and",
            image_size[1],
            "pixels high.",
            file=sys.stderr,
        )
        raise SystemExit(1)

    rgb_list = list(img.getdata())
    color_map = {
        col0: 0b00,  # Unique Char 1 / Transparent
        col1: 0b01,  # Unique Char 2 / Unique Sprite 1
        col2: 0b10,  # Shared Char 1 / Unique Sprite 2
        col3: 0b11,  # Shared Char 2 / Shared Sprite
    }
    invalid_colors = set(rgb_list) - set(color_map)
    if invalid_colors:
        print(
            "ERROR: The following invalid colors were used:",
            ", ".join(map(_rgb_to_hex, invalid_colors)),
        )
        raise SystemExit(1)

    image_bytes = tuple(
        (color_map[c[0]] << 6)
        + (color_map[c[1]] << 4)
        + (color_map[c[2]] << 2)
        + color_map[c[3]]
        for c in _batched(rgb_list, 4)
    )
    # Pad image data to multiples of 8
    image_bytes += (0,) * (8 - (len(image_bytes) % 8))

    if language == "basic":
        line_number = 0 if line_number_arg is None else line_number_arg

        for data in _batched(image_bytes, 8):
            line_number_str = (
                "" if line_number_arg is None else f"{line_number} "
            )
            print(f"{line_number_str}DATA", ", ".join(map(str, data)))
            line_number += line_increment
    else:
        batch_size = 1 if is_character else 3
        for data in _batched(image_bytes, batch_size):
            print(".BYTE", ", ".join(f"%{b:08b}" for b in data))


if __name__ == "__main__":
    main()
