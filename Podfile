source 'https://github.com/CocoaPods/Specs.git'
platform :ios, :deployment_target => '14.0'

inhibit_all_warnings!
use_frameworks!

target :iNaturalist do
  pod 'Firebase/Analytics'
  pod 'Firebase/Crashlytics'
  pod 'JWT', '2.2.0'
  pod 'FBSDKCoreKit', '14.1.0'
  pod 'FBSDKLoginKit', '14.1.0'
  pod 'Bolts', '1.9.1'
  pod 'FontAwesomeKit', '2.2.1'
  pod 'BlocksKit', '2.2.5'
  pod 'GeoJSONSerialization', '0.0.4'
  pod 'AFNetworking', '3.2.0'
  pod 'UIColor-HTMLColors', '1.0.0'
  pod 'SVPullToRefresh', '0.4.1'
  pod 'PDKTStickySectionHeadersCollectionViewLayout', '0.1'
  pod 'GoogleSignIn', '6.2.4'
  pod 'SSZipArchive', '0.3.2'
  pod 'ActionSheetPicker-3.0', '1.3.12'
  pod 'NXOAuth2Client', :git => 'https://github.com/inaturalist/OAuth2Client', :branch => 'iNat'
  pod 'RaptureXML', '1.0.1'
  pod 'DCRoundSwitch', '0.0.1'
  pod 'VTAcknowledgementsViewController', '0.15'
  pod 'AcknowList'
  pod 'YLProgressBar', '3.9.0'
  pod 'PBRevealViewController'
  pod 'SDWebImage', '4.0.0'
  pod 'JDStatusBarNotification', '1.5.2'
  pod 'MBProgressHUD', '0.9.1'
  pod 'NSString_stripHtml', '0.1.0'
  pod 'Mantle', '1.5.8'
  pod 'ICViewPager', :git => 'https://github.com/alexshepard/ICViewPager.git', :commit => '4c45423b6a36fb38753af86a1050b6a3a1d548b8'
  pod 'Realm', '~>10'
  pod 'ARSafariActivity'
  pod 'M13ProgressSuite', :git => 'https://github.com/rogerioth/M13ProgressSuite.git'
  pod 'MHVideoPhotoGallery', :git => 'https://github.com/alexshepard/MHVideoPhotoGallery', :commit => '0a343f12b60c8719a280db73b1e2b6d25fef164a'
  pod 'Down', :git => 'https://github.com/ocshing/Down-gfm'
  pod 'SimpleKeychain'
  pod 'JDFTooltips', '1.0'

  target :iNaturalistTests do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|

    # workaround for https://github.com/CocoaPods/CocoaPods/issues/11477
    if target.name == 'Realm'
      create_symlink_phase = target.shell_script_build_phases.find { |x| x.name == 'Create Symlinks to Header Folders' }
      create_symlink_phase.always_out_of_date = "1"
    end
  
    target.build_configurations.each do |config|
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
    end 
  end
end
