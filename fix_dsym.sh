#!/bin/bash

# Script to fix Firebase dSYM issues in archive
ARCHIVE_PATH="./AdRadar.xcarchive"
DERIVED_DATA_PATH="$HOME/Library/Developer/Xcode/DerivedData/AdRadar-eqfwsqncqsfpopanrhwdshyrcgrl/Build/Products/Release-iphoneos"

echo "🔧 Fixing Firebase dSYM issues..."

# Create dSYMs directory if it doesn't exist
mkdir -p "$ARCHIVE_PATH/dSYMs"

# Find and copy Firebase framework dSYMs
find "$DERIVED_DATA_PATH" -name "*.framework" -type d | while read framework; do
    framework_name=$(basename "$framework" .framework)
    
    # Look for dSYM in the framework itself
    if [ -d "$framework/$framework_name.dSYM" ]; then
        echo "📁 Copying dSYM for $framework_name"
        cp -R "$framework/$framework_name.dSYM" "$ARCHIVE_PATH/dSYMs/"
    fi
    
    # Look for dSYM in the build products
    if [ -d "$DERIVED_DATA_PATH/$framework_name.framework.dSYM" ]; then
        echo "📁 Copying dSYM for $framework_name from build products"
        cp -R "$DERIVED_DATA_PATH/$framework_name.framework.dSYM" "$ARCHIVE_PATH/dSYMs/"
    fi
done

echo "✅ dSYM fix completed!" 