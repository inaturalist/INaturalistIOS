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

class INatTabBarController: UITabBarController {
   
   var observingTaxonId: Int?
   lazy var slideInTransitioningDelegate = SlideInPresentationManager()

   override func viewDidLoad() {
      self.customizableViewControllers = nil
      
      // tab bar delegate to intercept selection of the "observe" tab
      self.delegate = self
      
      // configure camera VC
      if let cameraIcon = FAKIonIcons.iosCameraIcon(withSize: 45) {
         cameraIcon.addAttribute(NSAttributedString.Key.foregroundColor.rawValue, value: UIColor.lightGray)
         let cameraImg = cameraIcon.image(with: CGSize(width: 34, height: 45))?.withRenderingMode(.alwaysOriginal)
         if let vcs = self.viewControllers {
            let observeVC = vcs[2]
            observeVC.tabBarItem.image = cameraImg
            observeVC.tabBarItem.title = NSLocalizedString("Observe", comment: "Title for New Observation Tab Bar Button")
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
      Analytics.sharedClient()?.event(kAnalyticsEventNewObservationCameraStart)
      
      let camera = UIImagePickerController()
      camera.delegate = self
      camera.mediaTypes = ["public.image"]
      camera.sourceType = .camera
      
      self.present(camera, animated: true, completion: nil)
   }
   
   func showCameraRoll() {
      Analytics.sharedClient()?.event(kAnalyticsEventNewObservationLibraryStart)
      
      if #available(iOS 14, *) {
         let photoLibrary = PHPhotoLibrary.shared()
         let authStatus = PHPhotoLibrary.authorizationStatus(for: PHAccessLevel.readWrite)
         print(authStatus)
         
         
         PHPhotoLibrary.requestAuthorization(for: .readWrite) { (status) in
            print("new status is \(status)")
         }
         
         var config = PHPickerConfiguration(photoLibrary: photoLibrary)
         config.filter = .images
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
   
   func newObsNoPhoto() {
      Analytics.sharedClient()?.event(kAnalyticsEventNewObservationNoPhotoStart)
      
      let o = ExploreObservationRealm()
      o.uuid = UUID().uuidString.lowercased()
      o.timeCreated = Date()
      o.timeUpdatedLocally = Date()
      // photoless observation defaults to now
      o.timeObserved = Date()
      
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

      // photo was taken now
      o.timeObserved = Date()
      
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

// required for UIImagePickerController delegate
extension INatTabBarController: UINavigationControllerDelegate { }

extension INatTabBarController: PHPickerViewControllerDelegate {
   @available(iOS 14, *)
   func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
      picker.dismiss(animated: true, completion: nil)
      
      guard let result = results.first else { return }
      print(result)
      
      guard let assetId = result.assetIdentifier else { return }
      let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [ assetId ], options: nil)
      guard let asset = fetchResult.firstObject else { return }
      
      let confirm = ConfirmPhotoViewController()
      confirm.assets = [ asset ]
      if let taxonId = self.observingTaxonId,
         let taxon = ExploreTaxonRealm.object(forPrimaryKey: NSNumber(value: taxonId))
      {
         confirm.taxon = taxon
      }
      
      let nav = UINavigationController(rootViewController: confirm)
      self.present(nav, animated: true, completion: nil)
   }
}
