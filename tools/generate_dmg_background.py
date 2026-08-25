import math
import struct
import zlib
import os

def generate_retina_dmg_background(out_path="packaging/macos/dmg_background.png"):
    width, height = 660, 400
    scale = 2
    w = width * scale
    h = height * scale
    
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

    # 1. Background gradient (sleek dark macOS style: #161822 -> #0B0C12)
    for y in range(h):
        t = y / h
        ease_t = 0.5 - 0.5 * math.cos(t * math.pi)
        r = int(22 + (10 - 22) * ease_t)
        g = int(24 + (12 - 24) * ease_t)
        b = int(34 + (18 - 34) * ease_t)
        for x in range(w):
            idx = (y * w + x) * 4
            img[idx] = r
            img[idx + 1] = g
            img[idx + 2] = b
            img[idx + 3] = 255

    # 2. Ambient glowing aura in the center (Musly purple/cyan gradient)
    cx, cy = w // 2, int(190 * scale)
    glow_rx = int(200 * scale)
    glow_ry = int(140 * scale)
    for y in range(max(0, cy - glow_ry), min(h, cy + glow_ry)):
        for x in range(max(0, cx - glow_rx), min(w, cx + glow_rx)):
            dx = (x - cx) / glow_rx
            dy = (y - cy) / glow_ry
            dist = math.sqrt(dx * dx + dy * dy)
            if dist < 1.0:
                glow = (1.0 - dist) ** 2.2
                # Left-to-right color shift across the glow (violet to teal)
                shift = (x - (cx - glow_rx)) / (glow_rx * 2)
                gr = int(150 * (1 - shift) + 60 * shift)
                gg = int(80 * (1 - shift) + 180 * shift)
                gb = int(255)
                set_pixel(x, y, gr, gg, gb, int(glow * 45))

    # Helper: draw antialiased circle
    def draw_circle(circ_x, circ_y, radius, r, g, b, a):
        r_ceil = int(radius + 2)
        for y in range(int(circ_y - r_ceil), int(circ_y + r_ceil + 1)):
            for x in range(int(circ_x - r_ceil), int(circ_x + r_ceil + 1)):
                d = math.hypot(x - circ_x, y - circ_y)
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
        steps = int(length * 2.5)
        for i in range(steps + 1):
            t = i / steps
            px = x0 + t * (x1 - x0)
            py = y0 + t * (y1 - y0)
            draw_circle(px, py, thickness / 2.0, r, g, b, a)

    # 3. Drop zone rings under App and Applications
    # Left icon center: 180, 190
    # Right icon center: 480, 190
    def draw_dropzone(center_x, center_y, label_text, is_destination=False):
        box_w = int(144 * scale)
        box_h = int(144 * scale)
        bx = int(center_x * scale - box_w / 2)
        by = int(center_y * scale - box_h / 2)
        rad = int(28 * scale)
        
        # Soft fill
        fill_alpha = 14 if not is_destination else 22
        fill_r, fill_g, fill_b = (255, 255, 255) if not is_destination else (90, 170, 255)
        for y in range(by, by + box_h):
            for x in range(bx, bx + box_w):
                # Check rounded corners
                dx = max(0, max(bx + rad - x, x - (bx + box_w - rad)))
                dy = max(0, max(by + rad - y, y - (by + box_h - rad)))
                if math.hypot(dx, dy) <= rad:
                    set_pixel(x, y, fill_r, fill_g, fill_b, fill_alpha)

        # Border
        stroke = 2.0 * scale
        border_r, border_g, border_b = (255, 255, 255) if not is_destination else (110, 190, 255)
        border_a = 40 if not is_destination else 90
        
        # Top / Bottom
        draw_line(bx + rad, by, bx + box_w - rad, by, stroke, border_r, border_g, border_b, border_a)
        draw_line(bx + rad, by + box_h, bx + box_w - rad, by + box_h, stroke, border_r, border_g, border_b, border_a)
        # Left / Right
        draw_line(bx, by + rad, bx, by + box_h - rad, stroke, border_r, border_g, border_b, border_a)
        draw_line(bx + box_w, by + rad, bx + box_w, by + box_h - rad, stroke, border_r, border_g, border_b, border_a)

    draw_dropzone(180, 190, "Musly.app", is_destination=False)
    draw_dropzone(480, 190, "Applications", is_destination=True)

    # 4. Modern Glowing Action Arrow (X: 276..384, Y: 190)
    arr_x1 = int(278 * scale)
    arr_x2 = int(382 * scale)
    arr_y = int(190 * scale)
    thick = 5.0 * scale

    # Outer arrow glow
    glow_steps = int((arr_x2 - arr_x1) * 2)
    for i in range(glow_steps + 1):
        t = i / glow_steps
        px = arr_x1 + t * (arr_x2 - arr_x1)
        draw_circle(px, arr_y, thick * 2.2, 120, 150, 255, 30)

    # Gradient arrow stem
    for i in range(glow_steps + 1):
        t = i / glow_steps
        px = arr_x1 + t * (arr_x2 - arr_x1)
        sr = int(190 * (1 - t) + 80 * t)
        sg = int(120 * (1 - t) + 210 * t)
        sb = int(255)
        draw_circle(px, arr_y, thick / 2.0, sr, sg, sb, 240)

    # Arrow head (chevron)
    arrow_head = int(22 * scale)
    head_angle_y = int(18 * scale)
    
    # Glow chevron
    draw_line(arr_x2, arr_y, arr_x2 - arrow_head, arr_y - head_angle_y, thick * 2.0, 90, 200, 255, 40)
    draw_line(arr_x2, arr_y, arr_x2 - arrow_head, arr_y + head_angle_y, thick * 2.0, 90, 200, 255, 40)
    
    # Sharp chevron
    draw_line(arr_x2, arr_y, arr_x2 - arrow_head, arr_y - head_angle_y, thick, 90, 215, 255, 255)
    draw_line(arr_x2, arr_y, arr_x2 - arrow_head, arr_y + head_angle_y, thick, 90, 215, 255, 255)

    # 5. Clean Vector Typography (Smooth Antialiased Strokes)
    # Define vector stroke font for clean modern typography
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
        # Measure width
        total_w = 0
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
            total_w += cw + (2.5 * char_scale)

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

    # Render Header Title: "MUSLY"
    render_text("MUSLY", w // 2, int(48 * scale), 2.6 * scale, 3.2 * scale, 255, 255, 255, 245)

    # Render Subtitle: "Drag Musly to the Applications folder to install"
    render_text("DRAG MUSLY TO APPLICATIONS TO INSTALL", w // 2, int(82 * scale), 1.05 * scale, 1.8 * scale, 175, 185, 205, 195)

    # Render label under arrow: "INSTALL"
    render_text("INSTALL", w // 2, int(222 * scale), 0.9 * scale, 1.6 * scale, 140, 190, 255, 170)

    # PNG encoding
    def write_png():
        sig = b'\x89PNG\r\n\x1a\n'
        ihdr_data = struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0)
        ihdr_crc = zlib.crc32(b'IHDR' + ihdr_data) & 0xffffffff
        ihdr_chunk = struct.pack('>I', len(ihdr_data)) + b'IHDR' + ihdr_data + struct.pack('>I', ihdr_crc)
        
        raw_scanlines = bytearray()
        for y in range(h):
            raw_scanlines.append(0)
            start = y * w * 4
            raw_scanlines.extend(img[start:start + w * 4])
            
        compressed = zlib.compress(raw_scanlines, 9)
        idat_crc = zlib.crc32(b'IDAT' + compressed) & 0xffffffff
        idat_chunk = struct.pack('>I', len(compressed)) + b'IDAT' + compressed + struct.pack('>I', idat_crc)
        
        iend_crc = zlib.crc32(b'IEND') & 0xffffffff
        iend_chunk = struct.pack('>I', 0) + b'IEND' + struct.pack('>I', iend_crc)
        
        return sig + ihdr_chunk + idat_chunk + iend_chunk

    png_bytes = write_png()
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, 'wb') as f:
        f.write(png_bytes)
    print(f"Generated Retina DMG background: {out_path} ({len(png_bytes)} bytes)")

if __name__ == '__main__':
    generate_retina_dmg_background('packaging/macos/dmg_background.png')
