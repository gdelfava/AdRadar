#!/bin/bash

# Build phase script to preserve Firebase dSYM files
# This script should be added as a "Run Script" build phase in Xcode

echo "🔧 Preserving Firebase dSYM files..."

# Get the build products directory
BUILD_PRODUCTS_DIR="${BUILT_PRODUCTS_DIR}"
ARCHIVE_PATH="${ARCHIVE_PATH}"

if [ -n "$ARCHIVE_PATH" ]; then
    echo "📁 Archive path: $ARCHIVE_PATH"
    
    # Create dSYMs directory in archive
    mkdir -p "$ARCHIVE_PATH/dSYMs"
    
    # Find all Firebase frameworks and their dSYMs
    find "$BUILD_PRODUCTS_DIR" -name "*Firebase*.framework" -type d | while read framework; do
        framework_name=$(basename "$framework" .framework)
        echo "📁 Processing framework: $framework_name"
        
        # Look for dSYM in the same directory as the framework
        dsym_path="$BUILD_PRODUCTS_DIR/$framework_name.framework.dSYM"
        if [ -d "$dsym_path" ]; then
            echo "📁 Copying dSYM: $framework_name.framework.dSYM"
            cp -R "$dsym_path" "$ARCHIVE_PATH/dSYMs/"
        fi
        
        # Also check if dSYM is inside the framework
        internal_dsym="$framework/$framework_name.dSYM"
        if [ -d "$internal_dsym" ]; then
            echo "📁 Copying internal dSYM: $framework_name"
            cp -R "$internal_dsym" "$ARCHIVE_PATH/dSYMs/"
        fi
    done
    
    echo "✅ Firebase dSYM preservation completed!"
else
    echo "⚠️  Not in archive build, skipping dSYM preservation"
fi 