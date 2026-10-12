import sys
from PIL import Image


def main():
    if len(sys.argv) < 3:
        print("Usage: python3 image_to_mem.py <input_image> <image.mem> [max_width] [max_height]")
        sys.exit(1)

    in_path = sys.argv[1]
    out_path = sys.argv[2]
    max_w = int(sys.argv[3]) if len(sys.argv) > 3 else 200
    max_h = int(sys.argv[4]) if len(sys.argv) > 4 else 300

    img = Image.open(in_path).convert('L')
    w, h = img.size
    scale = min(max_w / w, max_h / h, 1.0)
    if scale != 1.0:
        w, h = int(w * scale), int(h * scale)
        img = img.resize((w, h), Image.LANCZOS)

    pixels = list(img.getdata())

    with open(out_path, 'w') as f:
        for p in pixels:
            f.write('%02x\n' % p)

    print(f"Wrote {len(pixels)} pixels ({w}x{h}) to {out_path}")
    print("Set these in top_sobel_vga.v (or as Vivado generic overrides):")
    print(f"  IMG_WIDTH  = {w}")
    print(f"  IMG_HEIGHT = {h}")
    if w > 640 or h > 480:
        print("WARNING: image is larger than 640x480 and will not fit on screen.")


if __name__ == '__main__':
    main()
