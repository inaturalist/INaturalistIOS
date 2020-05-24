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

class INatTabBarController: UITabBarController {
    
    var observingTaxon: TaxonVisualization?
    
    override func viewDidLoad() {
        self.customizableViewControllers = nil;
        
        // tab bar delegate to intercept selection of the "observe" tab
        self.delegate = self;
        
        // configure camera VC
        if let cameraIcon = FAKIonIcons.iosCameraIcon(withSize: 45) {
            cameraIcon.addAttribute(NSAttributedString.Key.foregroundColor.rawValue, value: UIColor.lightGray);
            let cameraImg = cameraIcon.image(with: CGSize(width: 34, height: 45))?.withRenderingMode(.alwaysOriginal);
            if let vcs = self.viewControllers {
                let observeVC = vcs[2]
                observeVC.tabBarItem.image = cameraImg;
                observeVC.tabBarItem.title = NSLocalizedString("Observe", comment: "Title for New Observation Tab Bar Button")
            }
        }
        
        // default to me tab
        self.selectedIndex = 3;
        
        // our gallery controller doesn't support video
        Gallery.Config.tabsToShow = [.imageTab, .cameraTab]
        Gallery.Config.initialTab = .cameraTab;
        
        Gallery.Config.Camera.recordLocation = true;
        Gallery.Config.Camera.imageLimit = 4;
    }
    
    func triggerNewObservationFlow() {
        
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let takePhotoTitle = NSLocalizedString("Take Picture", comment: "Title for take photo button in new obs flow")
        sheet.addAction(UIAlertAction(title: takePhotoTitle, style: .default, handler: { _ in
            let gallery = GalleryController()
            Gallery.Config.tabsToShow = [.cameraTab]
            Gallery.Config.initialTab = .cameraTab;
            gallery.delegate = self
            let galleryNav = UINavigationController(rootViewController: gallery);
            galleryNav.navigationBar.isHidden = true;
            self.present(galleryNav, animated: true, completion: nil);
        }))
        
        let photoLibraryTitle = NSLocalizedString("Photo Library", comment: "Title for photo library button in new obs flow")
        sheet.addAction(UIAlertAction(title: photoLibraryTitle, style: .default, handler: { _ in
            let gallery = GalleryController()
            Gallery.Config.tabsToShow = [.imageTab]
            Gallery.Config.initialTab = .imageTab;
            gallery.delegate = self
            let galleryNav = UINavigationController(rootViewController: gallery);
            galleryNav.navigationBar.isHidden = true;
            self.present(galleryNav, animated: true, completion: nil);
        }))
        
        let noPhotoTitle = NSLocalizedString("No Photo", comment: "Title for photo library button in new obs flow")
        sheet.addAction(UIAlertAction(title: noPhotoTitle, style: .default, handler: { _ in
            let o = ExploreObservationRealm()
            o.uuid = UUID().uuidString.lowercased()
            o.timeCreated = Date()
            o.timeUpdatedLocally = Date()
            // photoless observation defaults to now
            o.timeObserved = Date()
            
            let confirmVC = ObsEditV2ViewController(nibName: nil, bundle: nil)
            confirmVC.standaloneObservation = o
            confirmVC.shouldContinueUpdatingLocation = true
            confirmVC.isMakingNewObservation = true
            
            let nav = UINavigationController(rootViewController: confirmVC)
            self.present(nav, animated: true, completion: nil)
            // TODO: taxon
        }))
        
        let cancelTitle = NSLocalizedString("Cancel", comment: "")
        sheet.addAction(UIAlertAction(title: cancelTitle, style: .cancel, handler: nil))
        
        present(sheet, animated: true, completion: nil)
    }
    
    @objc func triggerNewObservationFlowForTaxon(_ taxon: ExploreTaxonRealm?) {
        self.observingTaxon = taxon;
        let gallery = GalleryController();
        gallery.delegate = self;
        let galleryNav = UINavigationController(rootViewController: gallery);
        galleryNav.navigationBar.isHidden = true;
        present(galleryNav, animated: true, completion: nil);
    }
}

extension INatTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if let vcs = tabBarController.viewControllers {
            if vcs.firstIndex(of: viewController) == 2 {
                DispatchQueue.main.async {
                    self.triggerNewObservationFlow();
                }
                return false;
            }
        }
        
        return true;
    }
}

extension INatTabBarController: GalleryControllerDelegate {
    func galleryController(_ controller: GalleryController, didSelectImages images: [Image]) {
        let confirm = ConfirmPhotoViewController()
        confirm.assets = images.map { $0.asset }
        if let taxon = self.observingTaxon as? ExploreTaxonRealm {
            confirm.taxon = taxon
        }
        controller.navigationController?.pushViewController(confirm, animated: true)
    }
    
    func galleryController(_ controller: GalleryController, didSelectVideo video: Video) {
        controller.dismiss(animated: true, completion: nil);
    }
    
    func galleryController(_ controller: GalleryController, requestLightbox images: [Image]) {
        // do nothing
        return
    }
    
    func galleryControllerDidCancel(_ controller: GalleryController) {
        controller.dismiss(animated: true, completion: nil);
    }
}
