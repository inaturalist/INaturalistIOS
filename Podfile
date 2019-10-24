source 'https://github.com/CocoaPods/Specs.git'
platform :ios, :deployment_target => '9.3'

inhibit_all_warnings!

target :iNaturalist do
  pod 'Fabric'
  pod 'Crashlytics'
  pod 'Firebase/Analytics'
  pod 'JWT', '2.2.0'
  pod 'FBSDKCoreKit', '4.37.0'
  pod 'FBSDKLoginKit', '4.37.0'
  pod 'Bolts', '1.9.0'
  pod 'FontAwesomeKit', '2.2.1'
  pod 'HexColors', '2.3.0'
  pod 'BlocksKit', '2.2.5'
  pod 'GeoJSONSerialization', '0.0.4'
  pod 'AFNetworking', '3.2.0'
  pod 'UIColor-HTMLColors', '1.0.0'
  pod 'SVPullToRefresh', '0.4.1'
  pod 'PDKTStickySectionHeadersCollectionViewLayout', '0.1'
  pod 'GoogleSignIn', '4.4.0'
  pod 'SSZipArchive', '0.3.2'
  pod 'ActionSheetPicker-3.0', '1.3.12'
  pod 'NXOAuth2Client', '1.2.8'
  pod 'RaptureXML', '1.0.1'
  pod 'DCRoundSwitch', '0.0.1'
  pod 'VTAcknowledgementsViewController', '0.15'
  pod 'JDFTooltips', '1.0'
  pod 'CustomIOSAlertView', '0.9.3'
  pod 'YLProgressBar', '3.9.0'
  pod 'TapkuLibrary', '0.3.8'
  pod 'SWRevealViewController', '2.3.0'
  pod 'RestKit', '0.10.3'
  pod 'RestKit/Testing', '0.10.3'
  pod 'SDWebImage', '4.0.0'
  pod 'IFTTTLaunchImage', '0.4.4'
  pod 'JDStatusBarNotification', '1.5.2'
  pod 'MBProgressHUD', '0.9.1'
  pod 'VICMAImageView', '~> 1.0'
  pod 'Toast', '3.0'
  pod 'NSString_stripHtml', '0.1.0'
  pod 'Mantle', '1.5.8'
  pod 'ICViewPager', :git => 'https://github.com/alexshepard/ICViewPager.git', :commit => '4c45423b6a36fb38753af86a1050b6a3a1d548b8'
  pod 'Realm', '3.20.0'
  pod 'ARSafariActivity'
  pod 'M13ProgressSuite'
  pod 'TOCropViewController', '~> 2.3.5'
  pod 'MHVideoPhotoGallery', :git => 'https://github.com/alexshepard/MHVideoPhotoGallery', :commit => '0a343f12b60c8719a280db73b1e2b6d25fef164a'
  pod 'JSONKit', :git => 'https://github.com/alexshepard/JSONKit.git', :commit => '46343e0e46fa8390fed0e8fff6367adb745d7fdd'
  pod 'FileMD5Hash', :git => 'https://github.com/FutureWorkshops/FileMD5Hash.git', :commit => '6864c180c010ab4b0514ba5c025091e12ab01199'
  pod 'YLMoment', :git => 'https://github.com/inaturalist/YLMoment.git', :commit => '35521e9f80c23de6f885771f97a6c1febe245c00'
end

target :iNaturalistTests do
end

# Append to your Podfile
post_install do |installer_representation|
    installer_representation.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
        end
    end
end
