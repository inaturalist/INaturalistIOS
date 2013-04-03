INaturalistIOS
==============

INaturalistIOS is an iOS app for iNaturalist.org. It's a re-write of the old
Titanium-based app, and is still under development.

Setup
-----
We're using a number of submodules so there's a little more than cloning:

    git clone git@github.com:inaturalist/INaturalistIOS.git
    cd INaturalistIOS/
    cp config.h.example config.h # and edit to configure for your project
    git submodule init
    git submodule update
    cd Vendor/Facebook && ./scripts/build_framework.sh

That should get you set up for local development with the Simulator. If you want to test on actual devices you'll need to get a provisioning profile from Apple and configure the project to use it: https://developer.apple.com/ios/manage/overview/index.action.
