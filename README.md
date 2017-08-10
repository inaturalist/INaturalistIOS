INaturalistIOS
==============

INaturalistIOS is the official iOS app for submitting data to [iNaturalist.org](http://www.inaturalist.org).

Setup
-----

We use cocoapods for dependencies. Install it with: `gem install cocoapods`, then do `pod install` in this directory to install the INaturalistIOS dependencies..

You'll also need to copy `config.h.example` to `config.h` and fill in your details.

That should get you set up for local development with the Simulator. If you want to test on actual devices you'll need to get a provisioning profile from Apple and configure the project to use it: https://developer.apple.com/ios/manage/overview/index.action.

Translations
------------

We do our translations on Crowdin. Head over to https://crowdin.com/project/inaturalistios and create an account, and you can start suggesting translations there. Our team regularly exports translations from crowdin and imports them to this project.

Roadmap
-----

Check out our [Roadmap](https://github.com/inaturalist/INaturalistIOS/wiki/Roadmap) for details on where we're doing.

Getting Help
------------

Did you find this repository while searching for a solution to a problem with INaturalistIOS? Consider first checking in with the iNaturalist [Google Group](https://groups.google.com/forum/#!forum/inaturalist) to see if other users are reporting issues or to ask a question. If you're pretty sure there is a technical issue to raise, [submit an issue](https://github.com/inaturalist/INaturalistIOS/issues). A "good" issue is one that is:

- Reproducible, by you and others;
- Well-described, including:
    - what steps led to the problem;
    - a description the problem;
    - what you expected if the problem had not occurred;
    - the _exact_ error message if one was shown.
- Documented, if possible (such as by using screenshots)


