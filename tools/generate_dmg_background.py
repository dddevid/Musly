import math
import struct
import zlib
import os

def generate_dmg_background(out_path="packaging/macos/dmg_background.png"):
    # Target window dimensions: 660 x 400 points
    # In macOS Finder, a 660x400 px image with 72 DPI maps 1:1 to a 660x400 window
    w, h = 660, 400
    
    img = bytearray(w * h * 4)
    
    def set_pixel(x, y, r, g, b, a):
        if 0 <= x < w and 0 <= y < h:
            idx = (y * w + x) * 4
            src_a = a / 255.0
            dst_a = img[idx + 3] / 255.0
            out_a = src_a + dst_a * (1.0 - src_a)
            if out_a > 0:
                out_r = int((r * src_a + img[idx] * dst_a * (1.0 - src_a)) / out_a)
                out_g = int((g * src_a + img[idx + 1] * dst_a * (1.0 - src_a)) / out_a)
                out_b = int((b * src_a + img[idx + 2] * dst_a * (1.0 - src_a)) / out_a)
                img[idx] = min(255, max(0, out_r))
                img[idx + 1] = min(255, max(0, out_g))
                img[idx + 2] = min(255, max(0, out_b))
                img[idx + 3] = int(min(255, max(0, out_a * 255)))

    # 1. Background gradient (deep dark modern macOS style: #14161F to #0A0B10)
    for y in range(h):
        t = y / h
        ease_t = 0.5 - 0.5 * math.cos(t * math.pi)
        r = int(20 + (10 - 20) * ease_t)
        g = int(22 + (11 - 22) * ease_t)
        b = int(32 + (16 - 32) * ease_t)
        for x in range(w):
            idx = (y * w + x) * 4
            img[idx] = r
            img[idx + 1] = g
            img[idx + 2] = b
            img[idx + 3] = 255

    # 2. Ambient radial glow in the center behind the arrow
    cx, cy = w // 2, 190
    glow_rx = 180
    glow_ry = 120
    for y in range(max(0, cy - glow_ry), min(h, cy + glow_ry)):
        for x in range(max(0, cx - glow_rx), min(w, cx + glow_rx)):
            dx = (x - cx) / glow_rx
            dy = (y - cy) / glow_ry
            dist = math.sqrt(dx * dx + dy * dy)
            if dist < 1.0:
                glow = (1.0 - dist) ** 2.2
                shift = (x - (cx - glow_rx)) / (glow_rx * 2)
                gr = int(140 * (1 - shift) + 60 * shift)
                gg = int(80 * (1 - shift) + 170 * shift)
                gb = int(255)
                set_pixel(x, y, gr, gg, gb, int(glow * 40))

    # Helper: draw antialiased circle
    def draw_circle(circ_x, circ_y, radius, r, g, b, a):
        r_ceil = int(radius + 2)
        for y in range(int(circ_y - r_ceil), int(circ_y + r_ceil + 1)):
            for x in range(int(circ_x - r_ceil), int(circ_x + r_ceil + 1)):
                d = math.hypot(x - circ_x, y - cy if False else y - circ_y)
                if d <= radius - 0.5:
                    set_pixel(x, y, r, g, b, a)
                elif d < radius + 0.5:
                    aa = (radius + 0.5 - d) * a
                    set_pixel(x, y, r, g, b, int(aa))

    # Helper: draw antialiased line
    def draw_line(x0, y0, x1, y1, thickness, r, g, b, a):
        length = math.hypot(x1 - x0, y1 - y0)
        if length == 0:
            return
        steps = int(length * 3)
        for i in range(steps + 1):
            t = i / steps
            px = x0 + t * (x1 - x0)
            py = y0 + t * (y1 - y0)
            draw_circle(px, py, thickness / 2.0, r, g, b, a)

    # 3. Draw sleek arrow between icons (musly.app center: X=175, Y=190 -> Applications center: X=485, Y=190)
    # The arrow sits right in the middle: X=275 to X=385, Y=190
    arr_x1 = 275
    arr_x2 = 385
    arr_y = 190
    thick = 4.0

    # Outer glow
    glow_steps = int((arr_x2 - arr_x1) * 2)
    for i in range(glow_steps + 1):
        t = i / glow_steps
        px = arr_x1 + t * (arr_x2 - arr_x1)
        draw_circle(px, arr_y, thick * 2.5, 120, 150, 255, 30)

    # Arrow stem gradient
    for i in range(glow_steps + 1):
        t = i / glow_steps
        px = arr_x1 + t * (arr_x2 - arr_x1)
        sr = int(180 * (1 - t) + 80 * t)
        sg = int(110 * (1 - t) + 210 * t)
        sb = int(255)
        draw_circle(px, arr_y, thick / 2.0, sr, sg, sb, 245)

    # Arrow head (chevron)
    arrow_head = 18
    head_angle_y = 14
    # Glow chevron
    draw_line(arr_x2, arr_y, arr_x2 - arrow_head, arr_y - head_angle_y, thick * 2.2, 90, 200, 255, 45)
    draw_line(arr_x2, arr_y, arr_x2 - arrow_head, arr_y + head_angle_y, thick * 2.2, 90, 200, 255, 45)
    # Sharp chevron
    draw_line(arr_x2, arr_y, arr_x2 - arrow_head, arr_y - head_angle_y, thick, 90, 215, 255, 255)
    draw_line(arr_x2, arr_y, arr_x2 - arrow_head, arr_y + head_angle_y, thick, 90, 215, 255, 255)

    # 4. Clean Vector Typography
    VFONT = {
        'A': [(0, 10, 5, 0), (5, 0, 10, 10), (2, 6, 8, 6)],
        'B': [(0, 0, 0, 10), (0, 0, 7, 0), (7, 0, 8, 2), (8, 2, 7, 5), (0, 5, 7, 5), (7, 5, 8, 7), (8, 7, 7, 10), (0, 10, 7, 10)],
        'C': [(8, 0, 2, 0), (2, 0, 0, 3), (0, 3, 0, 7), (0, 7, 2, 10), (2, 10, 8, 10)],
        'D': [(0, 0, 0, 10), (0, 0, 6, 0), (6, 0, 9, 3), (9, 3, 9, 7), (9, 7, 6, 10), (0, 10, 6, 10)],
        'E': [(0, 0, 0, 10), (0, 0, 8, 0), (0, 5, 6, 5), (0, 10, 8, 10)],
        'F': [(0, 0, 0, 10), (0, 0, 8, 0), (0, 5, 5, 5)],
        'G': [(8, 1, 2, 0), (2, 0, 0, 3), (0, 3, 0, 7), (0, 7, 2, 10), (2, 10, 8, 10), (8, 10, 8, 5), (8, 5, 5, 5)],
        'H': [(0, 0, 0, 10), (8, 0, 8, 10), (0, 5, 8, 5)],
        'I': [(0, 0, 6, 0), (3, 0, 3, 10), (0, 10, 6, 10)],
        'J': [(6, 0, 6, 8), (6, 8, 4, 10), (4, 10, 1, 10), (1, 10, 0, 7)],
        'K': [(0, 0, 0, 10), (0, 5, 8, 0), (0, 5, 8, 10)],
        'L': [(0, 0, 0, 10), (0, 10, 7, 10)],
        'M': [(0, 10, 0, 0), (0, 0, 5, 7), (5, 7, 10, 0), (10, 0, 10, 10)],
        'N': [(0, 10, 0, 0), (0, 0, 8, 10), (8, 10, 8, 0)],
        'O': [(2, 0, 7, 0), (7, 0, 9, 3), (9, 3, 9, 7), (9, 7, 7, 10), (7, 10, 2, 10), (2, 10, 0, 7), (0, 7, 0, 3), (0, 3, 2, 0)],
        'P': [(0, 10, 0, 0), (0, 0, 6, 0), (6, 0, 8, 2), (8, 2, 8, 4), (8, 4, 6, 6), (0, 6, 6, 6)],
        'Q': [(2, 0, 7, 0), (7, 0, 9, 3), (9, 3, 9, 7), (9, 7, 7, 10), (7, 10, 2, 10), (2, 10, 0, 7), (0, 7, 0, 3), (0, 3, 2, 0), (5, 7, 9, 11)],
        'R': [(0, 10, 0, 0), (0, 0, 6, 0), (6, 0, 8, 2), (8, 2, 8, 4), (8, 4, 6, 6), (0, 6, 6, 6), (4, 6, 8, 10)],
        'S': [(8, 2, 6, 0), (6, 0, 2, 0), (2, 0, 0, 2), (0, 2, 1, 4), (1, 4, 7, 6), (7, 6, 8, 8), (8, 8, 6, 10), (6, 10, 2, 10), (2, 10, 0, 8)],
        'T': [(0, 0, 8, 0), (4, 0, 4, 10)],
        'U': [(0, 0, 0, 7), (0, 7, 3, 10), (3, 10, 6, 10), (6, 10, 9, 7), (9, 7, 9, 0)],
        'V': [(0, 0, 4.5, 10), (4.5, 10, 9, 0)],
        'W': [(0, 0, 2.5, 10), (2.5, 10, 5, 4), (5, 4, 7.5, 10), (7.5, 10, 10, 0)],
        'X': [(0, 0, 8, 10), (0, 10, 8, 0)],
        'Y': [(0, 0, 4.5, 5), (9, 0, 4.5, 5), (4.5, 5, 4.5, 10)],
        'Z': [(0, 0, 8, 0), (8, 0, 0, 10), (0, 10, 8, 10)],
        ' ': [],
        '.': [(1, 9.5, 1.5, 9.5)],
    }

    def render_text(text, center_x, center_y, char_scale, line_thickness, r, g, b, a):
        text = text.upper()
        char_widths = []
        for ch in text:
            if ch == ' ':
                cw = 6 * char_scale
            elif ch in ('I', '.'):
                cw = 5 * char_scale
            elif ch in ('M', 'W'):
                cw = 12 * char_scale
            else:
                cw = 9.5 * char_scale
            char_widths.append(cw)

        total_w = sum(char_widths) + (len(text) - 1) * (2.5 * char_scale)
        cur_x = center_x - total_w / 2.0
        for i, ch in enumerate(text):
            cw = char_widths[i]
            segments = VFONT.get(ch, [])
            for seg in segments:
                x0 = cur_x + seg[0] * char_scale
                y0 = center_y - (5 * char_scale) + seg[1] * char_scale
                x1 = cur_x + seg[2] * char_scale
                y1 = center_y - (5 * char_scale) + seg[3] * char_scale
                draw_line(x0, y0, x1, y1, line_thickness, r, g, b, a)
            cur_x += cw + (2.5 * char_scale)

    # Render Header Title: "MUSLY" (centered horizontally at X=330, Y=45)
    render_text("MUSLY", w // 2, 45, 2.2, 2.5, 255, 255, 255, 245)

    # Render Subtitle: "Drag Musly to Applications to install" (centered horizontally at X=330, Y=78)
    render_text("DRAG MUSLY TO APPLICATIONS TO INSTALL", w // 2, 78, 0.95, 1.6, 175, 185, 205, 195)

    # PNG encoding with 72 DPI pHYs chunk
    def write_png():
        sig = b'\x89PNG\r\n\x1a\n'
        
        # IHDR
        ihdr_data = struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0)
        ihdr_crc = zlib.crc32(b'IHDR' + ihdr_data) & 0xffffffff
        ihdr_chunk = struct.pack('>I', len(ihdr_data)) + b'IHDR' + ihdr_data + struct.pack('>I', ihdr_crc)
        
        # pHYs (72 DPI = 2835 pixels per meter)
        phys_data = struct.pack('>IIB', 2835, 2835, 1)
        phys_crc = zlib.crc32(b'pHYs' + phys_data) & 0xffffffff
        phys_chunk = struct.pack('>I', len(phys_data)) + b'pHYs' + phys_data + struct.pack('>I', phys_crc)
        
        # IDAT
        raw_scanlines = bytearray()
        for y in range(h):
            raw_scanlines.append(0)
            start = y * w * 4
            raw_scanlines.extend(img[start:start + w * 4])
            
        compressed = zlib.compress(raw_scanlines, 9)
        idat_crc = zlib.crc32(b'IDAT' + compressed) & 0xffffffff
        idat_chunk = struct.pack('>I', len(compressed)) + b'IDAT' + compressed + struct.pack('>I', idat_crc)
        
        # IEND
        iend_crc = zlib.crc32(b'IEND') & 0xffffffff
        iend_chunk = struct.pack('>I', 0) + b'IEND' + struct.pack('>I', iend_crc)
        
        return sig + ihdr_chunk + phys_chunk + idat_chunk + iend_chunk

    png_bytes = write_png()
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, 'wb') as f:
        f.write(png_bytes)
    print(f"Generated DMG background: {out_path} ({len(png_bytes)} bytes)")

if __name__ == '__main__':
    generate_dmg_background('packaging/macos/dmg_background.png')
