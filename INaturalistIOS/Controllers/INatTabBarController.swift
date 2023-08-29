//
//  INatTabBarController.swift
//  iNaturalist
//
//  Created by Alex Shepard on 2/5/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

import UIKit
import Gallery
import FontAwesomeKit
import Photos
import PhotosUI
import CoreImage
import MBProgressHUD

class INatTabBarController: UITabBarController {
   
   var observingTaxonId: Int?
   lazy var slideInTransitioningDelegate = SlideInPresentationManager()
   
   override func viewDidLoad() {
      self.customizableViewControllers = nil
      
      // tab bar delegate to intercept selection of the "observe" tab
      self.delegate = self
      
      // configure camera VC
      if #available(iOS 13.0, *) {
         if let vcs = self.viewControllers {
            let observeVC = vcs[2]
            observeVC.tabBarItem.image = UIImage(systemName: "camera.fill")
            observeVC.tabBarItem.title = NSLocalizedString("Observe", comment: "Title for New Observation Tab Bar Button")
         }
      } else {
         if let cameraIcon = FAKIonIcons.iosCameraIcon(withSize: 45) {
            cameraIcon.addAttribute(NSAttributedString.Key.foregroundColor.rawValue, value: UIColor.lightGray)
            let cameraImg = cameraIcon.image(with: CGSize(width: 34, height: 45))?.withRenderingMode(.alwaysOriginal)
            if let vcs = self.viewControllers {
               let observeVC = vcs[2]
               observeVC.tabBarItem.image = cameraImg
               observeVC.tabBarItem.title = NSLocalizedString("Observe", comment: "Title for New Observation Tab Bar Button")
            }
         }
      }

      // default to me tab
      self.selectedIndex = 3
      
      // our gallery controller doesn't support video
      Gallery.Config.tabsToShow = [.imageTab, .cameraTab]
      Gallery.Config.initialTab = .cameraTab
      
      Gallery.Config.Camera.recordLocation = true
      Gallery.Config.Camera.imageLimit = 4
   }
   
   func showCamera() {
      var cameraFailTitle = ""
      var canAccessCamera = true

      let cameraAuthStatus = AVCaptureDevice.authorizationStatus(for: .video)
      if cameraAuthStatus == .denied {
         canAccessCamera = false
         cameraFailTitle = NSLocalizedString("iNaturalist doesn't have permission to access your camera.", comment: "alert title for camera denied")
      } else if cameraAuthStatus == .restricted {
         canAccessCamera = false
         cameraFailTitle = NSLocalizedString("iNaturalist has been restricted from camera access.", comment: "alert title for camera restricted")
      }
      
      if canAccessCamera {
         let camera = UIImagePickerController()
         camera.delegate = self
         camera.mediaTypes = ["public.image"]
         camera.sourceType = .camera
         
         self.present(camera, animated: true, completion: nil)
      } else {
         let msg = NSLocalizedString("Please update camera permissions to take photos with iNaturalist", comment: "alert msg to change camera permissions")
         let alert = UIAlertController(title: cameraFailTitle, message: msg, preferredStyle: .alert)
         alert.addAction(UIAlertAction(title: NSLocalizedString("Open Settings", comment: "open settings button title"), style: .default, handler: { _ in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString),
               UIApplication.shared.canOpenURL(settingsUrl)
            {
               UIApplication.shared.open(settingsUrl, options: [:], completionHandler: nil)
            }
         }))
         alert.addAction(UIAlertAction(title: NSLocalizedString("Never mind", comment: "decline to change cemra permissions button title"), style: .cancel, handler: nil))
         
         self.present(alert, animated: true, completion: nil)
      }
   }
   
   func showCameraRoll() {
      if #available(iOS 14, *) {
         var config = PHPickerConfiguration()
         config.filter = .images
         config.selectionLimit = 4
         let picker = PHPickerViewController(configuration: config)
         picker.delegate = self
         present(picker, animated: true, completion: nil)
      } else {
         let gallery = GalleryController()
         Gallery.Config.tabsToShow = [.imageTab]
         Gallery.Config.initialTab = .imageTab
         gallery.delegate = self
         let galleryNav = UINavigationController(rootViewController: gallery)
         galleryNav.navigationBar.isHidden = true
         
         self.present(galleryNav, animated: true, completion: nil)
      }
   }
   
   func showSoundRecorder() {
      let soundRecorder = SoundRecordViewController(nibName: nil, bundle: nil)
      soundRecorder.recorderDelegate = self
      let soundNav = UINavigationController(rootViewController: soundRecorder)
      
      self.present(soundNav, animated: true, completion: nil)
   }
   
   func newObsNoPhoto() {
      let o = ExploreObservationRealm()
      o.uuid = UUID().uuidString.lowercased()
      o.timeCreated = Date()
      o.timeUpdatedLocally = Date()
      o.geoprivacy = "open"
      // photoless observation defaults to now
      o.timeObserved = Date()
      o.observedTimeZone = TimeZone.current.identifier;
      
      if let taxonId = self.observingTaxonId,
         let taxon = ExploreTaxonRealm.object(forPrimaryKey: NSNumber(value: taxonId))
      {
         o.taxon = taxon
      }
      
      let confirmVC = ObsEditV2ViewController(nibName: nil, bundle: nil)
      confirmVC.standaloneObservation = o
      confirmVC.shouldContinueUpdatingLocation = true
      confirmVC.isMakingNewObservation = true
      
      
      let nav = UINavigationController(rootViewController: confirmVC)
      self.present(nav, animated: true, completion: nil)
   }
   
   
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      if segue.identifier == "MediaPickerSegue" {
         if let mediaPicker = segue.destination as? MediaPickerViewController {
            mediaPicker.mediaPickerDelegate = self
            mediaPicker.transitioningDelegate = slideInTransitioningDelegate
         }
      }
   }
   
   func triggerNewObservationFlow() {
      self.performSegue(withIdentifier: "MediaPickerSegue", sender: nil)
   }
   
   @objc func triggerNewObservationFlowForTaxon(_ taxon: ExploreTaxonRealm?) {
      if let taxon = taxon {
         self.observingTaxonId = taxon.taxonId
      }
      
      self.performSegue(withIdentifier: "MediaPickerSegue", sender: nil)
   }
}

extension INatTabBarController: UITabBarControllerDelegate {
   func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
      if let vcs = tabBarController.viewControllers {
         if vcs.firstIndex(of: viewController) == 2 {
            DispatchQueue.main.async {
               self.triggerNewObservationFlow()
            }
            return false
         }
      }
      
      return true
   }
}

extension INatTabBarController: GalleryControllerDelegate {
   func galleryController(_ controller: GalleryController, didSelectImages images: [Image]) {
      let confirm = ConfirmPhotoViewController()
      confirm.assets = images.map { $0.asset }
      if let taxonId = self.observingTaxonId,
         let taxon = ExploreTaxonRealm.object(forPrimaryKey: NSNumber(value: taxonId))
      {
         confirm.taxon = taxon
      }
      controller.navigationController?.pushViewController(confirm, animated: true)
   }
   
   func galleryController(_ controller: GalleryController, didSelectVideo video: Video) {
      controller.dismiss(animated: true, completion: nil)
   }
   
   func galleryController(_ controller: GalleryController, requestLightbox images: [Image]) {
      // do nothing
      return
   }
   
   func galleryControllerDidCancel(_ controller: GalleryController) {
      controller.dismiss(animated: true, completion: nil)
   }
}

extension INatTabBarController: MediaPickerDelegate {
   func choseMediaPickerItemAtIndex(_ idx: Int) {
      dismiss(animated: true) {
         if idx == 0 {
            self.newObsNoPhoto()
         } else if idx == 1 {
            self.showCamera()
         } else if idx == 2 {
            self.showCameraRoll()
         } else if idx == 3 {
            self.showSoundRecorder()
         }
      }
   }
}

extension INatTabBarController: UIImagePickerControllerDelegate {
   func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      picker.dismiss(animated: true, completion: nil)
   }
   
   public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
      guard let image = info[.originalImage] as? UIImage else {
         // no image, dismiss and give up
         picker.dismiss(animated: true, completion: nil)
         return
      }
      
      guard let imageStore = ImageStore.shared() else {
         picker.dismiss(animated: true, completion: nil)
         return
      }
      
      let photoKey = imageStore.createKey()
      do {
         try imageStore.store(image, forKey:photoKey)
      } catch {
         picker.dismiss(animated: true, completion: nil)
         return
      }
      
      let imageData: Data?
      if var metadata = info[.mediaMetadata] as? [String: Any] {
         // check if we have a recent location that can be embbed
         // into the metadata.
         if let location = CLLocationManager().location,
            let gpsDict = location.inat_GPSDictionary(),
            location.timestamp.timeIntervalSinceNow > -300
         {
            metadata[kCGImagePropertyGPSDictionary as String] = gpsDict
         }
         
         imageData = image.inat_JPEGDataRepresentation(withMetadata: metadata, quality: 0.9)
      } else {
         imageData = image.jpegData(compressionQuality: 0.9)
      }
      
      if let imageData = imageData {
         do {
            try PHPhotoLibrary.shared().performChangesAndWait {
               let request = PHAssetCreationRequest.forAsset()
               request.addResource(with: .photo, data: imageData, options: nil)
               request.creationDate = Date()
               
               // this updates the ios photos database but not exif
               if let location = CLLocationManager().location,
                  location.timestamp.timeIntervalSinceNow > -300
               {
                  request.location = location
               }
            }
         } catch { } // silently continue if this save operation fails
      }
      
      // with the standard image picker, no need to show confirmation screen
      let o = ExploreObservationRealm()
      o.uuid = UUID().uuidString.lowercased()
      o.timeCreated = Date()
      o.timeUpdatedLocally = Date()
      o.geoprivacy = "open"
      
      // photo was taken now
      o.timeObserved = Date()
      o.observedTimeZone = TimeZone.current.identifier;
      
      let op = ExploreObservationPhotoRealm()
      op.uuid = UUID().uuidString.lowercased()
      op.timeCreated = Date()
      op.timeUpdatedLocally = Date()
      op.position = 0
      op.photoKey = photoKey
      
      o.observationPhotos.add(op)
      
      if let taxonId = self.observingTaxonId,
         let taxon = ExploreTaxonRealm.object(forPrimaryKey: NSNumber(value: taxonId))
      {
         o.taxon = taxon
      }
      
      let editVC = ObsEditV2ViewController(nibName: nil, bundle: nil)
      editVC.standaloneObservation = o
      // photo was taken at the current location
      editVC.shouldContinueUpdatingLocation = true
      editVC.isMakingNewObservation = true
      
      picker.setNavigationBarHidden(false, animated: true)
      picker.pushViewController(editVC, animated: true)
   }   
}

extension INatTabBarController: SoundRecorderDelegate {
   func recordedSound(recorder: SoundRecordViewController, uuidString: String) {
      let o = ExploreObservationRealm()
      o.uuid = UUID().uuidString.lowercased()
      o.timeCreated = Date()
      o.timeUpdatedLocally = Date()
      o.geoprivacy = "open"
      
      // observation was made now
      o.timeObserved = Date()
      
      let obsSound = ExploreObservationSoundRealm()
      obsSound.uuid = uuidString
      obsSound.timeUpdatedLocally = Date()
      
      o.observationSounds.add(obsSound)
      
      if let taxonId = self.observingTaxonId,
         let taxon = ExploreTaxonRealm.object(forPrimaryKey: NSNumber(value: taxonId))
      {
         o.taxon = taxon
      }
      
      let editVC = ObsEditV2ViewController(nibName: nil, bundle: nil)
      editVC.standaloneObservation = o
      // observation was taken at the current location
      editVC.shouldContinueUpdatingLocation = true
      editVC.isMakingNewObservation = true
      
      recorder.navigationController?.pushViewController(editVC, animated: true)
   }
   
   func cancelled(recorder: SoundRecordViewController) {
      recorder.dismiss(animated: true, completion: nil)
   }
}

// required for UIImagePickerController delegate
extension INatTabBarController: UINavigationControllerDelegate { }

extension INatTabBarController: PHPickerViewControllerDelegate {
   @available(iOS 14, *)
   func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
      picker.dismiss(animated: true, completion: nil)
      
      if results.count == 0 {
         // user cancelled
         return
      }
      
      // for sorting since the fetch can come back out of order
      var resultsToPhotoKeys = [PHPickerResult: String]()
      for result in results {
         resultsToPhotoKeys[result] = ImageStore.shared().createKey()
      }
      var numLoaded = 0
      
      var takenDateForObs: Date? = nil
      var takenTimezoneForObs: TimeZone? = nil
      var takenLatitudeForObs: Double? = nil
      var takenLongitudeForObs: Double? = nil
      var takenGeoAccuracyForObs: Double? = nil
      
      if let hud = MBProgressHUD.showAdded(to: self.view, animated: true) {
         hud.removeFromSuperViewOnHide = true
         hud.dimBackground = true
         hud.labelText = NSLocalizedString("Creating Observation...", comment:"HUD text when creating a new observation from multiple photos")
      }
      
      for result in results {
         
         // we can use the exact same load callback but have to call it with the
         // explicit type identifier
         let loadCallback = { (url: URL?, error: Error?) in
            
            if let error = error {
               DispatchQueue.main.async {
                  MBProgressHUD.hideAllHUDs(for: self.view, animated: false)
                  
                  var localizedDescription = error.localizedDescription
                  
                  // check for an underlying error, which can happen with icloud stuff
                  // if there is one, we want to show the underlying error localized desc
                  let error = error as NSError
                  if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError {
                     let baseMsg = NSLocalizedString("We're not able to fetch your photo from iCloud: %@", comment: "base error message when icloud photo fetch fails")
                     localizedDescription = String(format: baseMsg, underlyingError.localizedDescription)
                  }
                  
                  let alertTitle = NSLocalizedString("Photo Load Error", comment: "Title for photo library fetch error when making new obs")
                  let alert = UIAlertController(title: alertTitle, message: localizedDescription, preferredStyle: .alert)
                  alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                  self.present(alert, animated: true, completion: nil)
               }
               
               return
            } else if let url = url, let image = UIImage(contentsOfFile: url.path) {
               
               // copy the file into my ImageStore
               guard let imageStore = ImageStore.shared() else {
                  DispatchQueue.main.async {
                     MBProgressHUD.hideAllHUDs(for: self.view, animated: false)
                     
                     let alertTitle = NSLocalizedString("Photo Load Error", comment: "Title for photo library error when making new obs")
                     let alertMsg = NSLocalizedString("ImageStore Creation Error", comment: "Message when we can't make the image store for the app")
                     let alert = UIAlertController(title: alertTitle, message: alertMsg, preferredStyle: .alert)
                     alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                     self.present(alert, animated: true, completion: nil)
                  }
                  
                  return
               }
               
               let photoKey = resultsToPhotoKeys[result]
               do {
                  try imageStore.store(image, forKey:photoKey)
                  numLoaded += 1
               } catch {
                  DispatchQueue.main.async {
                     MBProgressHUD.hideAllHUDs(for: self.view, animated: false)
                     
                     let alertTitle = NSLocalizedString("Photo Load Error", comment: "Title for photo library error when making new obs")
                     let alertMsg = NSLocalizedString("ImageStore Save Error", comment: "Message when we can't save to the app image store")
                     let alert = UIAlertController(title: alertTitle, message: alertMsg, preferredStyle: .alert)
                     alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default, handler: nil))
                     self.present(alert, animated: true, completion: nil)
                  }
                  
                  return
               }
               
               if let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) {
                  let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil)
                  if let dict = imageProperties as? [String: Any] {
                     if (takenDateForObs == nil) {
                        // still need to look for a taken date
                        if let exif = dict["{Exif}"] as? [String: Any] {
                           
                           let df = DateFormatter()
                           df.calendar = Calendar(identifier: .gregorian)
                           df.dateFormat = "yyyy:MM:dd HH:mm:ss"
                           
                           // sometimes different fields are populated, based on how & where the
                           // photo was digitized.
                           var tzOffset: String? = nil
                           if let tzOffsetExif = exif["OffsetTimeDigitized"] as? String {
                              tzOffset = tzOffsetExif
                           } else if let tzOffsetExif = exif["OffsetTime"] as? String {
                              tzOffset = tzOffsetExif
                           } else if let tzOffsetExif = exif["OffsetTimeOriginal"] as? String {
                              tzOffset = tzOffsetExif
                           }
                           
                           if let tzOffset = tzOffset {
                              let tzDateFormatter = DateFormatter()
                              tzDateFormatter.dateFormat = "ZZZZZ"
                              
                              if let tzDate = tzDateFormatter.date(from: tzOffset),
                                 let gmtDate = tzDateFormatter.date(from: "+00:00")
                              {
                                 var timeDiff: Double = 0
                                 if tzOffset.hasPrefix("-") {
                                    timeDiff = tzDate.timeIntervalSince(gmtDate) * -1
                                 } else {
                                    timeDiff = gmtDate.timeIntervalSince(tzDate)
                                 }
                                 
                                 if let tz = TimeZone(secondsFromGMT: Int(timeDiff)) {
                                    takenTimezoneForObs = tz
                                    df.timeZone = tz
                                 }
                              }
                           }

                           
                           if let takenDateExif = exif["DateTimeOriginal"] as? String,
                              let takenDate = df.date(from: takenDateExif)
                           {
                                 takenDateForObs = takenDate
                           }
                        }
                     }
                     
                     if takenLatitudeForObs == nil || takenLongitudeForObs == nil {
                        if let gps = dict["{GPS}"] as? [String: Any] {
                           if let latitude = gps["Latitude"] as? NSNumber,
                              let longitude = gps["Longitude"] as? NSNumber,
                              let latitudeRef = gps["LatitudeRef"] as? String,
                              let longitudeRef = gps["LongitudeRef"] as? String {
                                                      
                              if latitudeRef == "S" {
                                 takenLatitudeForObs = latitude.doubleValue * -1
                              } else {
                                 takenLatitudeForObs = latitude.doubleValue
                              }
                              if longitudeRef == "W" {
                                 takenLongitudeForObs = -1 * longitude.doubleValue
                              } else {
                                 takenLongitudeForObs = longitude.doubleValue
                              }
                           }
                           if let hpositioningError = gps["HPositioningError"] as? NSNumber {
                              takenGeoAccuracyForObs = hpositioningError.doubleValue
                           }
                        }
                     }
                  }
               }
               
               if numLoaded == results.count {
                  // we've saved all the results to our photo library
                  // and can safely make our observation and move on
                  
                  DispatchQueue.main.async {
                     let o = ExploreObservationRealm()
                     
                     o.uuid = UUID().uuidString.lowercased()
                     o.timeCreated = Date()
                     o.timeUpdatedLocally = Date()
                     o.geoprivacy = "open"
                     
                     if let latitude = takenLatitudeForObs {
                        o.latitude = latitude
                     }
                     if let longitude = takenLongitudeForObs {
                        o.longitude = longitude
                     }
                     if let accuracy = takenGeoAccuracyForObs {
                        o.privatePositionalAccuracy = accuracy
                     }
                     if let date = takenDateForObs {
                        o.timeObserved = date
                     }
                     if let tz = takenTimezoneForObs {
                        o.observedTimeZone = tz.identifier
                     }
                     
                     var position = 0
                     for result in results {
                        let photoKey = resultsToPhotoKeys[result]
                        
                        let op = ExploreObservationPhotoRealm()
                        op.uuid = UUID().uuidString.lowercased()
                        op.timeCreated = Date()
                        op.timeUpdatedLocally = Date()
                        op.position = position
                        op.photoKey = photoKey
                        
                        o.observationPhotos.add(op)
                        
                        position += 1
                     }
                     
                     if let taxonId = self.observingTaxonId,
                        let taxon = ExploreTaxonRealm.object(forPrimaryKey: NSNumber(value: taxonId))
                     {
                        o.taxon = taxon
                     }
                     
                     MBProgressHUD.hideAllHUDs(for: self.view, animated: false)

                     let editVC = ObsEditV2ViewController(nibName: nil, bundle: nil)
                     editVC.standaloneObservation = o
                     // photo was taken at the current location
                     editVC.shouldContinueUpdatingLocation = false
                     editVC.isMakingNewObservation = true
                     
                     let editVCNav = UINavigationController(rootViewController: editVC)
                     self.present(editVCNav, animated: true)
                  }
               }
            }
         }
         
         if (result.itemProvider.hasItemConformingToTypeIdentifier("public.jpeg")) {
            result.itemProvider.loadFileRepresentation(forTypeIdentifier: "public.jpeg", completionHandler: loadCallback)
         } else if (result.itemProvider.hasItemConformingToTypeIdentifier("public.png")) {
            result.itemProvider.loadFileRepresentation(forTypeIdentifier: "public.png", completionHandler: loadCallback)
         } else if (result.itemProvider.hasItemConformingToTypeIdentifier("com.adobe.raw-image")) {
            result.itemProvider.loadFileRepresentation(forTypeIdentifier: "com.adobe.raw-image", completionHandler: loadCallback)
         }
      }
   }
}


