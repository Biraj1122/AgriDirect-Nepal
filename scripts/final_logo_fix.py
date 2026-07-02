from PIL import Image, ImageOps
import math

def generate_safe_logo():
    # 1. Load the original high-quality source
    src_path = 'C:/Users/Asus Tuf/StudioProjects/farmtech_agridirect/assets/images/logo.png'
    img = Image.open(src_path)

    # 2. Extract components precisely
    # Graphical Circle: BBox for the top part
    circle_part = img.crop((367, 384, 1285, 384 + 485))
    c_bbox = circle_part.getbbox()
    if c_bbox: circle_part = circle_part.crop(c_bbox)

    # Text Part: "AgriDirect Nepal"
    text_part = img.crop((367, 1268 - 185, 1285, 1268))
    t_bbox = text_part.getbbox()
    if t_bbox: text_part = text_part.crop(t_bbox)

    # 3. Combine into a centered vertical stack
    gap = 20
    content_w = max(circle_part.width, text_part.width)
    content_h = circle_part.height + gap + text_part.height

    content_img = Image.new('RGBA', (content_w, content_h), (0, 0, 0, 0))
    content_img.paste(circle_part, ((content_w - circle_part.width)//2, 0), circle_part)
    content_img.paste(text_part, ((content_w - text_part.width)//2, circle_part.height + gap), text_part)

    target_size = 1024

    # 4. Generate IN-APP LOGO (logo_full.png)
    # This must fit inside the CIRCULAR container in the app.
    # The container is a circle, so the rectangle content must be inscribed.
    # Radius of container = target_size / 2
    # Diagonal of content must be <= Diameter of safe circle.
    in_app_safe_diameter = target_size * 0.90 # 90% of circle for margin
    content_diagonal = math.sqrt(content_w**2 + content_h**2)

    scale_in_app = in_app_safe_diameter / content_diagonal
    nw_in, nh_in = int(content_w * scale_in_app), int(content_h * scale_in_app)
    content_in_app = content_img.resize((nw_in, nh_in), Image.Resampling.LANCZOS)

    logo_full = Image.new('RGBA', (target_size, target_size), (0, 0, 0, 0))
    logo_full.paste(content_in_app, ((target_size - nw_in)//2, (target_size - nh_in)//2), content_in_app)
    logo_full.save('C:/Users/Asus Tuf/StudioProjects/farmtech_agridirect/assets/images/logo_full.png')
    logo_full.save('C:/Users/Asus Tuf/StudioProjects/farmtech_agridirect/assets/images/logo_adaptive.png')

    # 5. Generate SMARTPHONE LAUNCHER ICON (icon_launcher_full.png)
    # On Android, adaptive icons zoom in on the foreground.
    # To match Facebook/Chrome fitting, we must use a MUCH smaller foreground.
    # Standard safe zone is 66%, but professional icons often use ~50-55% for the primary mark.
    launcher_safe_diameter = target_size * 0.55 # Scale down to 55% to prevent zoom/clipping

    scale_launcher = launcher_safe_diameter / content_diagonal
    nw_la, nh_la = int(content_w * scale_launcher), int(content_h * scale_launcher)
    content_launcher = content_img.resize((nw_la, nh_la), Image.Resampling.LANCZOS)

    launcher_icon = Image.new('RGBA', (target_size, target_size), (0, 0, 0, 0))
    launcher_icon.paste(content_launcher, ((target_size - nw_la)//2, (target_size - nh_la)//2), content_launcher)

    launcher_icon.save('C:/Users/Asus Tuf/StudioProjects/farmtech_agridirect/assets/images/icon_launcher_full.png')
    launcher_icon.save('C:/Users/Asus Tuf/StudioProjects/farmtech_agridirect/assets/images/icon_launcher_adaptive.png')

    print(f"Generated safe in-app logo (90% diag fitting)")
    print(f"Generated fitted launcher icon (55% diag fitting) - matches professional apps.")

if __name__ == "__main__":
    generate_safe_logo()
