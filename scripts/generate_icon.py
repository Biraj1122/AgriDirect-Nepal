from PIL import Image, ImageDraw, ImageFont
import os

def generate_icons():
    # Brand color (Fresh Green)
    primary_color = (29, 158, 117)  # #1D9E75
    bg_color = (255, 255, 255)     # White
    text_color = primary_color

    # 1. Generate icon_launcher_full.png (Standard Icon)
    size = 1024
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # Background circle
    draw.ellipse([50, 50, size-50, size-50], fill=bg_color, outline=primary_color, width=40)

    # Load font
    try:
        font = ImageFont.truetype("arial.ttf", 150)
        sub_font = ImageFont.truetype("arial.ttf", 100)
    except:
        font = ImageFont.load_default()
        sub_font = ImageFont.load_default()

    # Draw text
    left, top, right, bottom = draw.textbbox((0, 0), "AgriDirect", font=font)
    w, h = right - left, bottom - top
    draw.text(((size-w)/2, (size/2) - h - 20), "AgriDirect", font=font, fill=text_color)

    left, top, right, bottom = draw.textbbox((0, 0), "Nepal", font=sub_font)
    w2, h2 = right - left, bottom - top
    draw.text(((size-w2)/2, (size/2) + 20), "Nepal", font=sub_font, fill=text_color)

    output_path = 'assets/images/icon_launcher_full.png'
    img.save(output_path)
    print(f"Generated {output_path}")

    # 2. Generate icon_launcher_adaptive.png (Adaptive Icon Foreground)
    adaptive_img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw_adaptive = ImageDraw.Draw(adaptive_img)

    try:
        font_a = ImageFont.truetype("arial.ttf", 140)
        sub_font_a = ImageFont.truetype("arial.ttf", 90)
    except:
        font_a = ImageFont.load_default()
        sub_font_a = ImageFont.load_default()

    left, top, right, bottom = draw_adaptive.textbbox((0, 0), "AgriDirect", font=font_a)
    w, h = right - left, bottom - top
    draw_adaptive.text(((size-w)/2, (size/2) - h - 10), "AgriDirect", font=font_a, fill=text_color)

    left, top, right, bottom = draw_adaptive.textbbox((0, 0), "Nepal", font=sub_font_a)
    w2, h2 = right - left, bottom - top
    draw_adaptive.text(((size-w2)/2, (size/2) + 10), "Nepal", font=sub_font_a, fill=text_color)

    adaptive_output_path = 'assets/images/icon_launcher_adaptive.png'
    adaptive_img.save(adaptive_output_path)
    print(f"Generated {adaptive_output_path}")

if __name__ == "__main__":
    generate_icons()
