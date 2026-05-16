#!/bin/bash

# Download and unzip iOS framework
IOS_URL="https://github.com/sk3llo/ffmpeg_kit_flutter/releases/download/8.0.0-min-gpl/ffmpeg-kit-ios-min-gpl-8.0.0.zip"
mkdir -p Frameworks
curl -L $IOS_URL -o frameworks.zip
unzip -o frameworks.zip -d Frameworks
rm frameworks.zip

# Delete bitcode from all frameworks (required for App Store)
xcrun bitcode_strip -r Frameworks/ffmpegkit.framework/ffmpegkit -o Frameworks/ffmpegkit.framework/ffmpegkit
xcrun bitcode_strip -r Frameworks/libavcodec.framework/libavcodec -o Frameworks/libavcodec.framework/libavcodec
xcrun bitcode_strip -r Frameworks/libavdevice.framework/libavdevice -o Frameworks/libavdevice.framework/libavdevice
xcrun bitcode_strip -r Frameworks/libavfilter.framework/libavfilter -o Frameworks/libavfilter.framework/libavfilter
xcrun bitcode_strip -r Frameworks/libavformat.framework/libavformat -o Frameworks/libavformat.framework/libavformat
xcrun bitcode_strip -r Frameworks/libavutil.framework/libavutil -o Frameworks/libavutil.framework/libavutil
xcrun bitcode_strip -r Frameworks/libswresample.framework/libswresample -o Frameworks/libswresample.framework/libswresample
xcrun bitcode_strip -r Frameworks/libswscale.framework/libswscale -o Frameworks/libswscale.framework/libswscale

# Convert each framework into an XCFramework with device and arm64 simulator variants.
for fw in Frameworks/*.framework; do
  fwname=$(basename "$fw" .framework)
  fwpath="$fw/$fwname"
  tmpdir=$(mktemp -d "/tmp/${fwname}.XXXXXX")
  device_dir="$tmpdir/ios-arm64/$fwname.framework"
  simulator_dir="$tmpdir/ios-arm64-simulator/$fwname.framework"
  arm64_slice="$tmpdir/${fwname}_arm64"
  arm64e_slice="$tmpdir/${fwname}_arm64e"
  arm64_sim_slice="$tmpdir/${fwname}_arm64_sim"

  lipo "$fwpath" -thin arm64 -output "$arm64_slice"

  if lipo "$fwpath" -thin arm64e -output "$arm64e_slice" 2>/dev/null; then
    has_arm64e=1
  else
    has_arm64e=0
    rm -f "$arm64e_slice"
  fi

  xcrun vtool -set-build-version 7 12.1 18.5 -replace \
    -output "$arm64_sim_slice" "$arm64_slice"

  mkdir -p "$device_dir" "$simulator_dir"
  cp -R "$fw/" "$device_dir/"
  cp -R "$fw/" "$simulator_dir/"

  if [ "$has_arm64e" -eq 1 ]; then
    lipo "$arm64_slice" "$arm64e_slice" -create -output "$device_dir/$fwname"
  else
    cp "$arm64_slice" "$device_dir/$fwname"
  fi

  cp "$arm64_sim_slice" "$simulator_dir/$fwname"
  sed -i '' 's/iPhoneOS/iPhoneSimulator/g' "$simulator_dir/Info.plist"

  xcodebuild -create-xcframework \
    -framework "$device_dir" \
    -framework "$simulator_dir" \
    -output "Frameworks/$fwname.xcframework"

  rm -rf "$tmpdir"
done

rm -rf Frameworks/*.framework
