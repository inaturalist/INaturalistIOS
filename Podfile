source 'https://github.com/CocoaPods/Specs.git'
platform :ios, :deployment_target => '8.0'

inhibit_all_warnings!

target :iNaturalist do
  pod 'JWT', '2.2.0'
  pod 'Fabric', '1.5.4'
  pod 'Crashlytics', '3.3.3'
  pod 'FBSDKCoreKit', '4.10.1'
  pod 'FBSDKLoginKit', '4.10.1'
  pod 'Bolts', '1.8.4'
  pod 'FontAwesomeKit', '2.2.0'
  pod 'HexColors', '2.3.0'
  pod 'BlocksKit', '2.2.5'
  pod 'GeoJSONSerialization', '0.0.4'
  pod 'AFNetworking', '2.6.3'
  pod 'UIColor-HTMLColors', '1.0.0'
  pod 'SlackTextViewController', '1.9'
  pod 'SVPullToRefresh', '0.4.1'
  pod 'PDKTStickySectionHeadersCollectionViewLayout', '0.1'
  pod 'googleplus-ios-sdk', '1.7.1'
  pod 'SSZipArchive', '0.3.2'
  pod 'ActionSheetPicker-3.0', '1.3.12'
  pod 'NXOAuth2Client', '1.2.8'
  pod 'RaptureXML', '1.0.1'
  pod 'DCRoundSwitch', '0.0.1'
  pod 'QBImagePickerController', '3.4.0'
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
  pod 'Realm', '2.5.1'
  pod 'ARSafariActivity'
  pod 'Amplitude-iOS', '~> 3.7.0'
  pod 'M13ProgressSuite'
  pod 'MHVideoPhotoGallery', :git => 'https://github.com/alexshepard/MHVideoPhotoGallery', :commit => '63c1c3d3578a913c26956b1c9c9f4411a8cfe226'
  pod 'JSONKit', :git => 'https://github.com/alexshepard/JSONKit.git', :commit => '46343e0e46fa8390fed0e8fff6367adb745d7fdd'
  pod 'FileMD5Hash', :git => 'https://github.com/JoeKun/FileMD5Hash.git', :commit => '6864c180c010ab4b0514ba5c025091e12ab01199'
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
