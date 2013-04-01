INaturalistIOS
==============

INaturalistIOS is an iOS app for iNaturalist.org. It's a re-write of the old
Titanium-based app, and is still under development.

Setup
-----
We're using a number of submodules so there's a little more than cloning:

    git clone git@github.com:inaturalist/INaturalistIOS.git
    git submodule init
    git submodule update
    cp config.h.example config.h # and edit to configure for your project
    cd Vendor/Facebook && ./scripts/build_framework.sh
