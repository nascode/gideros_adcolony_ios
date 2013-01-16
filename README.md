AdColony iOS Plugin for Gideros
=======================

AdColony iOS plugin for Gideros

Installation
------------
1. Add `adcolony.mm` to your XCode project
2. Download latest AdColony SDK (this plugin is tested on version 2.0.1.29)
3. Add `AdColonyPublic.h` and `libAdColony.a` from SDK to your XCode project
4. Add frameworks: 
 * AdSupport (set it to optional)
 * CoreMedia
 * MessageUI
 * EventKit
 * EventKitUI
 * CFNetwork
 * CoreTelephony (optional)
 * MediaPlayer
 * SystemConfiguration
 * libAdColony.a
5. AdColony 2.0 SDK and up uses ARC (Automatic Reference Counting), so we must compile the SDK with ARC enabled. To do this go to XCode project properties > Build Phases tab, add `libAdColony.a` to Compile Sources panel and set its compiler flags to `-fobjc-arc`
6. On XCode project property select Build Setting tab and find `Other Linker Flags` entry, then add `-ObjC` flag

Usage
-----
After plugin installation, look at example project

Final Note
----------
This plugin has been tested on Gideros 2012.09.6 exported Xcodde project and XCode 4.5.2

The lua API is compatible with [AdColony Android Plugin for Gideros](https://github.com/zaniar/gideros_adcolony)
