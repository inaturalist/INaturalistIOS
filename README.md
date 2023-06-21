INaturalistIOS
==============

INaturalistIOS is the official iOS app for submitting data to [iNaturalist.org](http://www.inaturalist.org).

Setup
-----

We use cocoapods for dependencies. Install it with: `gem install cocoapods`, then do `pod install` in this directory to install the INaturalistIOS dependencies. If you run into the build error *Class 'RK_FIX_CATEGORY_BUGSNDictionary_RKAdditions' defined without specifying a base class*, then you will need to set the clang warning **Unintentional Root Class** to be something other than **Yes (Error)** for the RestKit target in the Pods project. We are moving away from RestKit in 2019 so hopefully this won't be an issue for long.

You'll also need to copy `config.h.example` to `INaturalistIOS/config.h` and fill in your details.

You'll also need to copy `GoogleService-Info.plist.example` to `INaturalistIOS/GoogleService-Info.plist`. This version of GoogleService will disable any firebase related features we use - crash reporting, debug logging, google signin, etc. If you want any of those features, you should signup with Google Firebase and once you have your own `GoogleService-Info.plist` file, copy it here. Some instructions are here: https://firebase.google.com/docs/ios/setup?authuser=1#register-app

That should get you set up for local development with the Simulator. If you want to test on actual devices you'll need to get a provisioning profile from Apple and configure the project to use it: https://developer.apple.com/ios/manage/overview/index.action.

If you run into errors with cocoapods, xcode 14.3, and rsync, follow the instructions [here](https://github.com/CocoaPods/CocoaPods/issues/11808#issuecomment-1509261607)

Translations
------------

We do our translations on Crowdin. Head over to https://crowdin.com/project/inaturalistios and create an account, and you can start suggesting translations there. Our team regularly exports translations from crowdin and imports them to this project.

Roadmap
-----

We're focusing active feature development in [iNaturalistReactNative](https://github.com/inaturalist/iNaturalistReactNative) now.

Getting Help
------------

Did you find this repository while searching for a solution to a problem with INaturalistIOS? Consider first checking in with the iNaturalist [Forum](https://forum.inaturalist.org) to see if other users are reporting issues or to ask a question. If you're pretty sure there is a technical issue to raise, [submit an issue](https://github.com/inaturalist/INaturalistIOS/issues). A "good" issue is one that is:

- Reproducible, by you and others;
- Well-described, including:
    - what steps led to the problem;
    - a description the problem;
    - what you expected if the problem had not occurred;
    - the _exact_ error message if one was shown.
- Documented, if possible (such as by using screenshots)


