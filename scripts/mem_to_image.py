import sys
from PIL import Image


def main():
    if len(sys.argv) < 5:
        print("Usage: python3 mem_to_image.py <output_full.mem> <width> <height> <result.png>")
        sys.exit(1)

    mem_path = sys.argv[1]
    w = int(sys.argv[2])
    h = int(sys.argv[3])
    out_png = sys.argv[4]

    with open(mem_path) as f:
        values = [int(line.strip(), 16) for line in f if line.strip()]

    expected = w * h
    if len(values) != expected:
        print(f"WARNING: expected {expected} pixels ({w}x{h}), got {len(values)}.")

    img = Image.new('L', (w, h), color=0)
    px = img.load()
    idx = 0
    for r in range(h):
        for c in range(w):
            if idx >= len(values):
                break
            px[c, r] = values[idx]
            idx += 1

    img.save(out_png)
    print(f"Saved {out_png} ({w}x{h})")


if __name__ == '__main__':
    main()
