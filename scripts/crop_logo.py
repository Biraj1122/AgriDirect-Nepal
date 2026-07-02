from PIL import Image
import os

def crop_and_combine():
    # Source image
    src_path = 'C:/Users/Asus Tuf/StudioProjects/farmtech_agridirect/assets/images/logo.png'
    img = Image.open(src_path)

    # Original content BBox: (367, 384, 1285, 1268)
    # We will manually define the crops based on this.

    # 1. Graphical Circle Logo (Top)
    # It starts at 384. Let's take the first 480 pixels of height.
    circle_part = img.crop((367, 384, 1285, 384 + 480))
    # Crop it tightly
    c_bbox = circle_part.getbbox()
    if c_bbox: circle_part = circle_part.crop(c_bbox)

    # 2. AgriDirect Nepal text (Bottom)
    # It ends at 1268. Let's take the last 180 pixels of height.
    text_part = img.crop((367, 1268 - 180, 1285, 1268))
    # Crop it tightly
    t_bbox = text_part.getbbox()
    if t_bbox: text_part = text_part.crop(t_bbox)

    # Combine them with a very small gap to save space
    gap = 10
    final_w = max(circle_part.width, text_part.width)
    final_h = circle_part.height + gap + text_part.height

    final_img = Image.new('RGBA', (final_w, final_h), (0, 0, 0, 0))
    final_img.paste(circle_part, ((final_w - circle_part.width)//2, 0), circle_part)
    final_img.paste(text_part, ((final_w - text_part.width)//2, circle_part.height + gap), text_part)

    # Save as logo_clean.png
    output_path = 'C:/Users/Asus Tuf/StudioProjects/farmtech_agridirect/assets/images/logo_clean.png'
    final_img.save(output_path)
    print(f"Generated {output_path} ({final_w}x{final_h})")

    target_size = 1024

    # logo_full: centered, scaled to 98% (almost filling the space)
    full_img = Image.new('RGBA', (target_size, target_size), (0, 0, 0, 0))
    scale = min(target_size * 0.98 / final_w, target_size * 0.98 / final_h)
    new_w = int(final_w * scale)
    new_h = int(final_h * scale)
    resized = final_img.resize((new_w, new_h), Image.Resampling.LANCZOS)
    full_img.paste(resized, ((target_size - new_w)//2, (target_size - new_h)//2), resized)
    full_img.save('C:/Users/Asus Tuf/StudioProjects/farmtech_agridirect/assets/images/logo_full.png')

    # logo_adaptive & icons: use slightly smaller scale for safety (85% instead of 66% to be "larger")
    adaptive_img = Image.new('RGBA', (target_size, target_size), (0, 0, 0, 0))
    scale_a = min(target_size * 0.85 / final_w, target_size * 0.85 / final_h)
    new_w_a = int(final_w * scale_a)
    new_h_a = int(final_h * scale_a)
    resized_a = final_img.resize((new_w_a, new_h_a), Image.Resampling.LANCZOS)
    adaptive_img.paste(resized_a, ((target_size - new_w_a)//2, (target_size - new_h_a)//2), resized_a)

    adaptive_img.save('C:/Users/Asus Tuf/StudioProjects/farmtech_agridirect/assets/images/logo_adaptive.png')
    adaptive_img.save('C:/Users/Asus Tuf/StudioProjects/farmtech_agridirect/assets/images/icon_launcher_full.png')
    adaptive_img.save('C:/Users/Asus Tuf/StudioProjects/farmtech_agridirect/assets/images/icon_launcher_adaptive.png')

if __name__ == "__main__":
    crop_and_combine()
