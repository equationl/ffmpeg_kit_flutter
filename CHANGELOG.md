## 3.1.0

* Added ProGuard rules
* Fixed the FFmpeg 8.0 compatibility issue across all platforms. The problem was that `all_channel_counts` was being set AFTER the filter was created, but FFmpeg 8.0 requires it to be set DURING filter creation.

## 3.0.0

* FFmpeg `v8.0.0` with [all the sweet perks](https://ffmpeg.org/index.html#news)

## 2.1.0

* Downgraded Kotlin from 2.2.0 to 1.8.22
* Added new jniLibs that support Kotlin 1.8

## 2.0.0

* Removed bundled Android FFmpeg (jniLibs, cpp, bindings)
* Added FFmpeg min using new Maven Central package

## 1.0.1

* Updated README.md
* Updated scripts

## 1.0.0

* Initial release
* FFmpeg version 7.1.1