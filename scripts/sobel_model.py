"""
Bit-exact NumPy reference model of rtl/sobel_core.v.

Mirrors the hardware exactly:
  * the 3x3 window at input position (row, col) covers rows row-3..row-1
    and columns col-2..col (the row buffers hold *previous* rows only),
  * |Gx| + |Gy| (Manhattan magnitude), saturated to 255,
  * output is written at (row, col); positions with row <= 2 or col <= 1
    are never written and stay 0, as in output_bram.

Usage:
    python sobel_model.py image.mem <width> <height> model_out.mem
    python sobel_model.py image.mem <width> <height> model_out.mem --compare output_full.mem
"""
import sys
import numpy as np


def read_mem(path):
    with open(path) as f:
        return np.array([int(l.strip(), 16) for l in f if l.strip()], dtype=np.int32)


def write_mem(path, data):
    with open(path, "w") as f:
        for v in data.ravel():
            f.write("%02x\n" % v)


def sobel_rtl_model(img):
    h, w = img.shape
    out = np.zeros((h, w), dtype=np.int32)
    # Window rows: top = row-3, mid = row-2, bot = row-1 ; cols: col-2, col-1, col
    top = img[0:h - 3, :]
    mid = img[1:h - 2, :]
    bot = img[2:h - 1, :]
    c0, c1, c2 = slice(0, w - 2), slice(1, w - 1), slice(2, w)
    gx = (top[:, c2] - top[:, c0]) + 2 * (mid[:, c2] - mid[:, c0]) + (bot[:, c2] - bot[:, c0])
    gy = (top[:, c2] + 2 * top[:, c1] + top[:, c0]) - (bot[:, c2] + 2 * bot[:, c1] + bot[:, c0])
    g = np.minimum(np.abs(gx) + np.abs(gy), 255)
    out[3:h, 2:w] = g
    return out


def main():
    if len(sys.argv) < 5:
        print(__doc__)
        sys.exit(1)
    in_path, w, h, out_path = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), sys.argv[4]
    img = read_mem(in_path).reshape(h, w)
    model = sobel_rtl_model(img)
    write_mem(out_path, model)
    print(f"Model output written to {out_path} ({w}x{h})")

    if "--compare" in sys.argv:
        rtl = read_mem(sys.argv[sys.argv.index("--compare") + 1]).reshape(h, w)
        diff = np.count_nonzero(model != rtl)
        if diff == 0:
            print(f"PASS: RTL output matches the model bit-for-bit ({w*h} pixels)")
        else:
            print(f"FAIL: {diff} of {w*h} pixels differ")
            sys.exit(2)


if __name__ == "__main__":
    main()
