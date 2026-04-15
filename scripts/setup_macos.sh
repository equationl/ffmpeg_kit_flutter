#!/bin/bash

# ============================================================
# Fix hardcoded Homebrew library paths for macOS arm64
# This script downloads FFmpeg frameworks and fixes dyld issues
# ============================================================

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "ERROR: Homebrew is not installed."
    echo "Please install Homebrew first: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

# Homebrew packages needed for fixing arm64 frameworks
HOMEBREW_PACKAGES=(
    "fontconfig"
    "freetype"
    "fribidi"
    "harfbuzz"
    "glib"
    "gettext"
    "pcre2"
    "graphite2"
    "libsamplerate"
    "srt"
    "libiconv"
    "libpng"
    "openssl@3"
)

# Install required Homebrew packages
echo "Checking Homebrew dependencies..."
for pkg in "${HOMEBREW_PACKAGES[@]}"; do
    if ! brew list "$pkg" &> /dev/null; then
        echo "  Installing $pkg..."
        brew install "$pkg"
    else
        echo "  $pkg already installed"
    fi
done

echo ""

# Download and unzip MacOS framework
MACOS_URL="https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/8.0.0-full-gpl/ffmpeg-kit-macos-full-gpl-8.0.0.zip"
mkdir -p Frameworks
curl -L $MACOS_URL -o frameworks.zip
unzip -o frameworks.zip -d Frameworks
rm frameworks.zip

# Delete bitcode from all frameworks
xcrun bitcode_strip -r Frameworks/ffmpegkit.framework/ffmpegkit -o Frameworks/ffmpegkit.framework/ffmpegkit
xcrun bitcode_strip -r Frameworks/libavcodec.framework/libavcodec -o Frameworks/libavcodec.framework/libavcodec
xcrun bitcode_strip -r Frameworks/libavdevice.framework/libavdevice -o Frameworks/libavdevice.framework/libavdevice
xcrun bitcode_strip -r Frameworks/libavfilter.framework/libavfilter -o Frameworks/libavfilter.framework/libavfilter
xcrun bitcode_strip -r Frameworks/libavformat.framework/libavformat -o Frameworks/libavformat.framework/libavformat
xcrun bitcode_strip -r Frameworks/libavutil.framework/libavutil -o Frameworks/libavutil.framework/libavutil
xcrun bitcode_strip -r Frameworks/libswresample.framework/libswresample -o Frameworks/libswresample.framework/libswresample
xcrun bitcode_strip -r Frameworks/libswscale.framework/libswscale -o Frameworks/libswscale.framework/libswscale

# ============================================================
# Fix hardcoded Homebrew library paths for arm64 architecture
# This fixes the dyld crash on machines without Homebrew
# ============================================================

FRAMEWORKS_DIR="Frameworks"
DYLIBS_DIR="$FRAMEWORKS_DIR/dylibs"

# Create directory for bundled dylibs
mkdir -p "$DYLIBS_DIR"

# Define Homebrew libraries to bundle
# These are libraries that are NOT available as system libraries
HOMEBREW_LIBS=(
    "libfontconfig.1.dylib:fontconfig"
    "libfreetype.6.dylib:freetype"
    "libfribidi.0.dylib:fribidi"
    "libharfbuzz.0.dylib:harfbuzz"
    "libglib-2.0.0.dylib:glib"
    "libintl.8.dylib:gettext"
    "libpcre2-8.0.dylib:pcre2"
    "libgraphite2.3.dylib:graphite2"
    "libsamplerate.0.dylib:libsamplerate"
    "libsrt.1.5.dylib:srt"
    "libiconv.2.dylib:libiconv"
    "libpng16.16.dylib:libpng"
    "libssl.3.dylib:openssl@3"
    "libcrypto.3.dylib:openssl@3"
)

# Copy Homebrew dylibs to Frameworks/dylibs
echo "Copying Homebrew libraries to Frameworks/dylibs..."
for lib_info in "${HOMEBREW_LIBS[@]}"; do
    lib_name="${lib_info%%:*}"
    lib_path="/opt/homebrew/opt/${lib_info#*:}/lib/$lib_name"
    if [ -f "$lib_path" ]; then
        cp -L "$lib_path" "$DYLIBS_DIR/$lib_name"
        chmod 644 "$DYLIBS_DIR/$lib_name"
        echo "  Copied: $lib_name"
    else
        echo "  WARNING: Not found: $lib_path"
    fi
done

# Define path replacements
# Format: "old_path:new_path"
PATH_REPLACEMENTS=(
    "/opt/homebrew/opt/zlib/lib/libz.1.dylib:/usr/lib/libz.1.dylib"
    "/opt/homebrew/opt/fontconfig/lib/libfontconfig.1.dylib:@rpath/dylibs/libfontconfig.1.dylib"
    "/opt/homebrew/opt/freetype/lib/libfreetype.6.dylib:@rpath/dylibs/libfreetype.6.dylib"
    "/opt/homebrew/opt/fribidi/lib/libfribidi.0.dylib:@rpath/dylibs/libfribidi.0.dylib"
    "/opt/homebrew/opt/harfbuzz/lib/libharfbuzz.0.dylib:@rpath/dylibs/libharfbuzz.0.dylib"
    "/opt/homebrew/opt/glib/lib/libglib-2.0.0.dylib:@rpath/dylibs/libglib-2.0.0.dylib"
    "/opt/homebrew/opt/gettext/lib/libintl.8.dylib:@rpath/dylibs/libintl.8.dylib"
    "/opt/homebrew/opt/pcre2/lib/libpcre2-8.0.dylib:@rpath/dylibs/libpcre2-8.0.dylib"
    "/opt/homebrew/opt/graphite2/lib/libgraphite2.3.dylib:@rpath/dylibs/libgraphite2.3.dylib"
    "/opt/homebrew/opt/libsamplerate/lib/libsamplerate.0.dylib:@rpath/dylibs/libsamplerate.0.dylib"
    "/opt/homebrew/opt/srt/lib/libsrt.1.5.dylib:@rpath/dylibs/libsrt.1.5.dylib"
    "/opt/homebrew/opt/libiconv/lib/libiconv.2.dylib:@rpath/dylibs/libiconv.2.dylib"
    "/opt/homebrew/opt/libpng/lib/libpng16.16.dylib:@rpath/dylibs/libpng16.16.dylib"
    "/opt/homebrew/opt/openssl@3/lib/libssl.3.dylib:@rpath/dylibs/libssl.3.dylib"
    "/opt/homebrew/opt/openssl@3/lib/libcrypto.3.dylib:@rpath/dylibs/libcrypto.3.dylib"
    # Handle Cellar paths (different Homebrew installations may use different paths)
    "/opt/homebrew/Cellar/openssl@3/*/lib/libssl.3.dylib:@rpath/dylibs/libssl.3.dylib"
    "/opt/homebrew/Cellar/openssl@3/*/lib/libcrypto.3.dylib:@rpath/dylibs/libcrypto.3.dylib"
)

# FFmpeg frameworks to fix
FFMPEG_FRAMEWORKS=(
    "libavcodec"
    "libavdevice"
    "libavfilter"
    "libavformat"
    "libavutil"
    "libswscale"
    "libswresample"
)

# Function to fix library paths in a binary (for arm64 architecture only)
fix_library_paths() {
    local binary="$1"

    # Check if the binary is a fat binary with arm64
    if lipo -info "$binary" 2>/dev/null | grep -q "arm64"; then
        echo "  Fixing arm64 slice in: $(basename $binary)"

        # Extract arm64 slice
        local temp_arm64="${binary}.arm64"
        lipo -extract arm64 "$binary" -output "$temp_arm64" 2>/dev/null

        # Apply path replacements
        for replacement in "${PATH_REPLACEMENTS[@]}"; do
            old_path="${replacement%%:*}"
            new_path="${replacement#*:}"
            install_name_tool -change "$old_path" "$new_path" "$temp_arm64" 2>/dev/null
        done

        # Fix any remaining Homebrew Cellar paths dynamically
        # Extract all dylib paths from the binary and fix them
        while IFS= read -r line; do
            if [[ "$line" == *"/opt/homebrew/Cellar/"* ]]; then
                cellar_path=$(echo "$line" | sed 's/^[[:space:]]*//' | cut -d' ' -f1)
                lib_name=$(basename "$cellar_path")
                # Check if we have this lib in our dylibs
                if [ -f "$DYLIBS_DIR/$lib_name" ]; then
                    install_name_tool -change "$cellar_path" "@rpath/dylibs/$lib_name" "$temp_arm64" 2>/dev/null
                fi
            fi
        done < <(otool -L "$temp_arm64" 2>/dev/null | grep "/opt/homebrew")

        # Check if x86_64 exists
        if lipo -info "$binary" 2>/dev/null | grep -q "x86_64"; then
            # Extract x86_64 slice
            local temp_x86_64="${binary}.x86_64"
            lipo -extract x86_64 "$binary" -output "$temp_x86_64" 2>/dev/null

            # Create universal binary
            lipo -create "$temp_arm64" "$temp_x86_64" -output "$binary" 2>/dev/null
            rm -f "$temp_x86_64"
        else
            # Only arm64
            mv "$temp_arm64" "$binary"
        fi
        rm -f "$temp_arm64"
    fi
}

echo ""
echo "Fixing FFmpeg frameworks..."

# Fix each FFmpeg framework
for framework in "${FFMPEG_FRAMEWORKS[@]}"; do
    framework_path="$FRAMEWORKS_DIR/$framework.framework/$framework"
    if [ -f "$framework_path" ]; then
        echo "Processing $framework..."
        fix_library_paths "$framework_path"
    fi
done

# Fix bundled dylibs (they also have Homebrew paths)
echo ""
echo "Fixing bundled dylibs..."

for lib_info in "${HOMEBREW_LIBS[@]}"; do
    lib_name="${lib_info%%:*}"
    dylib_path="$DYLIBS_DIR/$lib_name"
    if [ -f "$dylib_path" ]; then
        echo "Processing $lib_name..."

        # First, change the library ID to use @rpath
        install_name_tool -id "@rpath/dylibs/$lib_name" "$dylib_path" 2>/dev/null

        # Then fix all dependency paths
        for replacement in "${PATH_REPLACEMENTS[@]}"; do
            old_path="${replacement%%:*}"
            new_path="${replacement#*:}"
            install_name_tool -change "$old_path" "$new_path" "$dylib_path" 2>/dev/null
        done

        # Fix any remaining Homebrew Cellar paths dynamically
        while IFS= read -r line; do
            if [[ "$line" == *"/opt/homebrew/Cellar/"* ]]; then
                cellar_path=$(echo "$line" | sed 's/^[[:space:]]*//' | cut -d' ' -f1)
                dep_lib_name=$(basename "$cellar_path")
                # Check if we have this lib in our dylibs
                if [ -f "$DYLIBS_DIR/$dep_lib_name" ]; then
                    install_name_tool -change "$cellar_path" "@rpath/dylibs/$dep_lib_name" "$dylib_path" 2>/dev/null
                fi
            fi
        done < <(otool -L "$dylib_path" 2>/dev/null | grep "/opt/homebrew")
    fi
done

echo ""
echo "Done! Frameworks have been fixed for distribution."