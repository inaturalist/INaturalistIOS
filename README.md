INaturalistIOS
==============

INaturalistIOS is the official iOS app for submitting data to [iNaturalist.org](http://www.inaturalist.org).

Setup
-----

We've just finished transitioning to cocoapods: `gem install cocoapods`, then `pod install`.

You'll also need to copy `config.h.example` to `config.h` and fill in your details.

That should get you set up for local development with the Simulator. If you want to test on actual devices you'll need to get a provisioning profile from Apple and configure the project to use it: https://developer.apple.com/ios/manage/overview/index.action.

Roadmap
-----

- ~~Autoupload~~
- ~~Final screen of new observation flow~~
- ~~Observation Detail Screen~~
- ~~News Feed for Projects & Site News~~
- ~~Redo Project pages~~
- ~~Reuse Observation Detail Screen in the Explore Tab~~
- Background Uploading
- New User Onboarding
- Add photo for profile pic
- Make New Observation from Photo Activity
- Activity Feed
- Taxon Detail pages
- Taxon chooser (Pending no species guess test)
- Me tab adding Species and Identifications list (if bodes well on Android) 
- New Observation Flow 2.0
- Observation List Redesign (Me Tab)
- Explore Tab redux
- Better Stats & Leaderboards
- People
- Notifications from server (instead of polling server)
- Background Fetch
- Faving

Icebox (stuff that we might like to do someday)
-----
- Spotlight search for iNat user content
- Core data storage for explore content
- Tools for identifiers

Other stuff
-----
- RestKit upgrade or alternative?
- Upgrade to latest Facebook & G+ auth toolkits
