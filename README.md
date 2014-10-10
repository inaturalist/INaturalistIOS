INaturalistIOS
==============

INaturalistIOS is the official iOS app for submitting data to [iNaturalist.org](http://www.inaturalist.org).

Setup
-----

We're in the middle of transitioning from submodules to cocoapods. For now you'll need to do both:
`gem install cocoapods`, then `pod install`.

We're using a number of submodules so there's a little more than cloning:

    git clone git@github.com:inaturalist/INaturalistIOS.git
    cd INaturalistIOS/
    cp config.h.example config.h # and edit to configure for your project
    git submodule init
    git submodule update

That should get you set up for local development with the Simulator. If you want to test on actual devices you'll need to get a provisioning profile from Apple and configure the project to use it: https://developer.apple.com/ios/manage/overview/index.action.