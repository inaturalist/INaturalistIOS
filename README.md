# INaturalistIOS

INaturalistIOS is the official iOS app for submitting data to [iNaturalist.org](http://www.inaturalist.org).

## Setup

1. Ensure you have cocoapods installed with `gem install cocoapods`
2. Install dependencies with `pod install` in this directory
3. Copy `config.h.example` to `INaturalistIOS/config.h`
4. In `INaturalistIOS/config.h` fill in your [project keys](https://www.inaturalist.org/oauth/applications)
5. Create a [Firebase project](https://console.firebase.google.com/)
6. In the Firebase console for your app, click `Add app` and add an iOS app
7. Fill in bundle Id: `org.inaturalist.inaturalist`, app nickname, and store ID: `421397028`
8. Register the app and download the `GoogleService-Info.plist`
9. Move `GoogleService-Info.plist` to `INaturalistIOS/GoogleService-Info.plist`
10. Build + run app in xcode

This should get you set up for local development with the Simulator. If you want to test on actual devices you'll need to get a provisioning profile from Apple and configure the project to use it: https://developer.apple.com/ios/manage/overview/index.action.

⚠️ If you run into the build error _Class 'RK_FIX_CATEGORY_BUGSNDictionary_RKAdditions' defined without specifying a base class_, then you will need to set the clang warning **Unintentional Root Class** to be something other than **Yes (Error)** for the RestKit target in the Pods project. We are moving away from RestKit in 2019 so hopefully this won't be an issue for long.

## Translations

We do our translations on Crowdin. Head over to https://crowdin.com/project/inaturalistios and create an account, and you can start suggesting translations there. Our team regularly exports translations from crowdin and imports them to this project.

## Roadmap

We're focusing active feature development in [iNaturalistReactNative](https://github.com/inaturalist/iNaturalistReactNative) now.

## Getting Help

Did you find this repository while searching for a solution to a problem with INaturalistIOS? Consider first checking in with the iNaturalist [Forum](https://forum.inaturalist.org) to see if other users are reporting issues or to ask a question. If you're pretty sure there is a technical issue to raise, [submit an issue](https://github.com/inaturalist/INaturalistIOS/issues). A "good" issue is one that is:

- Reproducible, by you and others;
- Well-described, including:
  - what steps led to the problem;
  - a description the problem;
  - what you expected if the problem had not occurred;
  - the _exact_ error message if one was shown.
- Documented, if possible (such as by using screenshots)
