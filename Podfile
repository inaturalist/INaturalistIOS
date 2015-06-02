source 'https://github.com/CocoaPods/Specs.git'
platform :ios, :deployment_target => '7.0'

target :iNaturalist do
	pod 'CrashlyticsFramework', '2.2.10'
	pod 'FlurrySDK', '6.2.0'
	pod 'Facebook-iOS-SDK', '3.20.0'
	pod 'Bolts', '1.1.3'
	pod 'FontAwesomeKit', '2.2.0'
	pod 'HexColors', '2.2.1'
	pod 'BlocksKit', '2.2.5'
	pod 'SVProgressHUD', '1.1.3'
	pod 'GeoJSONSerialization', '0.0.4'
	pod 'AFNetworking', '1.3.4'
	pod 'MHVideoPhotoGallery', '1.6.6'
	pod 'UIColor-HTMLColors', '1.0.0'
	pod 'SlackTextViewController', '1.5'
	pod 'SVPullToRefresh', '0.4.1'
	pod 'PDKTStickySectionHeadersCollectionViewLayout', '0.1'
	pod 'googleplus-ios-sdk', '1.7.1'
	pod 'SSZipArchive', '0.3.2'
	pod 'ActionSheetPicker-3.0', '1.3.12'
	pod 'NXOAuth2Client', '1.2.8'
	pod 'RaptureXML', '1.0.1'
	pod 'DCRoundSwitch', '0.0.1'
	pod 'QBImagePickerController', '2.2.2'
	pod 'VTAcknowledgementsViewController', '0.13'
	pod 'JDFTooltips', '1.0'
	pod 'CustomIOSAlertView', '0.9.3'
	pod 'TapkuLibrary', '0.3.8'
	pod 'SWRevealViewController', '2.3.0'
	pod 'RestKit', '0.10.3'
	pod 'JSONKit', :git => 'https://github.com/alexshepard/JSONKit.git', :commit => '46343e0e46fa8390fed0e8fff6367adb745d7fdd'
	pod 'FileMD5Hash', :git => 'https://github.com/JoeKun/FileMD5Hash.git', :commit => '6864c180c010ab4b0514ba5c025091e12ab01199'
end

target :iNaturalistTests do
  pod 'Specta'
  pod 'Expecta'
end

# Append to your Podfile
post_install do |installer_representation|
    installer_representation.project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
        end
    end
end
