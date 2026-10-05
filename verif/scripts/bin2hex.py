#!/usr/bin/env python3
"""Convert a flat little-endian binary (objcopy -O binary) into a $readmemh
image with one 32-bit word per line, first word at the load base."""
import sys


def main():
    if len(sys.argv) != 3:
        sys.exit(f"usage: {sys.argv[0]} <in.bin> <out.hex>")
    data = open(sys.argv[1], "rb").read()
    data += b"\0" * (-len(data) % 4)
    with open(sys.argv[2], "w") as f:
        for i in range(0, len(data), 4):
            f.write(f"{int.from_bytes(data[i:i + 4], 'little'):08x}\n")


if __name__ == "__main__":
    main()
