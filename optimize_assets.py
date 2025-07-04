#!/usr/bin/env python3
"""
Asset Optimization Script for AdRadar
Compresses large PNG files to reduce memory usage
"""

import os
import shutil
from PIL import Image
import json

def optimize_png_file(input_path, output_path, max_width=1024, quality=85):
    """
    Optimize a PNG file by resizing and compressing
    """
    try:
        with Image.open(input_path) as img:
            # Get original size
            original_size = os.path.getsize(input_path)
            original_width, original_height = img.size
            
            print(f"Processing: {os.path.basename(input_path)}")
            print(f"  Original: {original_width}x{original_height}, {original_size / (1024*1024):.1f} MB")
            
            # Calculate new dimensions maintaining aspect ratio
            if max(original_width, original_height) > max_width:
                ratio = max_width / max(original_width, original_height)
                new_width = int(original_width * ratio)
                new_height = int(original_height * ratio)
                
                # Resize image
                img_resized = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
            else:
                img_resized = img
                new_width, new_height = original_width, original_height
            
            # Convert to RGB if necessary (for JPEG optimization)
            if img_resized.mode in ('RGBA', 'P'):
                # Create white background for transparent images
                background = Image.new('RGB', img_resized.size, (255, 255, 255))
                if img_resized.mode == 'P':
                    img_resized = img_resized.convert('RGBA')
                background.paste(img_resized, mask=img_resized.split()[-1] if img_resized.mode == 'RGBA' else None)
                img_resized = background
            
            # Save as optimized PNG or JPEG
            if input_path.lower().endswith('.png') and original_size > 5 * 1024 * 1024:  # 5MB+
                # Large PNGs -> convert to JPEG
                jpeg_path = output_path.replace('.png', '.jpg')
                img_resized.save(jpeg_path, 'JPEG', quality=quality, optimize=True)
                new_size = os.path.getsize(jpeg_path)
                print(f"  Optimized: {new_width}x{new_height}, {new_size / (1024*1024):.1f} MB (JPEG)")
            else:
                # Save as optimized PNG
                img_resized.save(output_path, 'PNG', optimize=True)
                new_size = os.path.getsize(output_path)
                print(f"  Optimized: {new_width}x{new_height}, {new_size / (1024*1024):.1f} MB (PNG)")
            
            savings = original_size - new_size
            savings_percent = (savings / original_size) * 100
            print(f"  Savings: {savings / (1024*1024):.1f} MB ({savings_percent:.1f}%)")
            
            return savings
            
    except Exception as e:
        print(f"Error processing {input_path}: {e}")
        return 0

def optimize_imageset(imageset_path):
    """
    Optimize an entire .imageset directory
    """
    total_savings = 0
    
    print(f"\n🖼️  Optimizing imageset: {os.path.basename(imageset_path)}")
    
    for filename in os.listdir(imageset_path):
        if filename.lower().endswith(('.png', '.jpg', '.jpeg')):
            input_file = os.path.join(imageset_path, filename)
            
            # Create backup
            backup_file = input_file + '.backup'
            if not os.path.exists(backup_file):
                shutil.copy2(input_file, backup_file)
            
            # Optimize
            savings = optimize_png_file(input_file, input_file)
            total_savings += savings
    
    return total_savings

def main():
    """
    Main optimization function
    """
    print("🚀 AdRadar Asset Optimization Tool")
    print("=" * 50)
    
    # Assets to optimize (the problematic ones)
    asset_paths = [
        "AdRadar/Assets.xcassets/LoginScreen.imageset",
        "AdRadar/Assets.xcassets/AppIcon.appiconset",
        "AdRadar/Assets.xcassets/image-wavy-lines-bg.imageset"
    ]
    
    total_savings = 0
    
    for asset_path in asset_paths:
        if os.path.exists(asset_path):
            savings = optimize_imageset(asset_path)
            total_savings += savings
        else:
            print(f"⚠️  Path not found: {asset_path}")
    
    print("\n" + "=" * 50)
    print(f"🎉 Total memory savings: {total_savings / (1024*1024):.1f} MB")
    print(f"💡 Estimated app size reduction: {total_savings / (1024*1024):.1f} MB")
    
    # Recommendations
    print("\n📋 Additional Recommendations:")
    print("1. Use .jpg for large photos/backgrounds")
    print("2. Use .png only for icons and transparent images")
    print("3. Consider using SF Symbols instead of custom icons")
    print("4. Use Asset Catalog's 'Preserve Vector Data' for scalable icons")
    print("5. Test app memory usage after optimization")

if __name__ == "__main__":
    main() 