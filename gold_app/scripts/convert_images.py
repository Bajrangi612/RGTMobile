import os
import sys

def convert_to_webp(directory):
    try:
        from PIL import Image
    except ImportError:
        print("\n❌ Error: 'Pillow' library is not found in this environment.")
        print("Please run this command first: python -m pip install Pillow\n")
        return
    
    # Ensure directory exists
    if not os.path.exists(directory):
        print(f"❌ Directory not found: {directory}")
        return

    files = [f for f in os.listdir(directory) if f.lower().endswith('.png')]
    
    if not files:
        print("ℹ️ No PNG files found to convert.")
        return

    print(f"🚀 Found {len(files)} images to convert.")
    
    count = 0
    for filename in files:
        file_path = os.path.join(directory, filename)
        name_without_ext = os.path.splitext(filename)[0]
        output_path = os.path.join(directory, f"{name_without_ext}.webp")
        
        try:
            with Image.open(file_path) as img:
                img.save(output_path, "WEBP", quality=80)
                
            os.remove(file_path)
            count += 1
            print(f" ✅ Converted: {filename} -> {name_without_ext}.webp")
        except Exception as e:
            print(f" ❌ Failed to convert {filename}: {e}")

    print(f"\n✨ Done! Converted {count} images.")

if __name__ == "__main__":
    # Check if we are in gold_app or root
    if os.path.exists(os.path.join("gold_app", "assets", "images")):
        assets_dir = os.path.join("gold_app", "assets", "images")
    elif os.path.exists(os.path.join("assets", "images")):
        assets_dir = os.path.join("assets", "images")
    else:
        assets_dir = os.path.join("..", "assets", "images")

    convert_to_webp(assets_dir)
