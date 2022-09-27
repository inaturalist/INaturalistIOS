//
//  GalleryWrapper.swift
//  iNaturalist
//
//  Created by Alex Shepard on 5/24/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

import Foundation
import Gallery

@objc protocol GalleryWrapperDelegate {
    @objc func galleryDidSelect(_ images: [UIImage])
    @objc func galleryDidCancel()
}

@objc class GalleryWrapper: NSObject {
    @objc weak var wrapperDelegate: GalleryWrapperDelegate?

    @objc public func gallery() -> UIViewController {
        let gallery = GalleryController()
        gallery.delegate = self
        Gallery.Config.tabsToShow = [.imageTab]
        Gallery.Config.initialTab = .imageTab
        return gallery
    }
}

extension GalleryWrapper: GalleryControllerDelegate {
    func galleryController(_ controller: GalleryController, didSelectImages images: [Image]) {
        Image.resolve(images: images) { [unowned self] uiimages in
            // just skip anything we can't resolve
            self.wrapperDelegate?.galleryDidSelect( uiimages.compactMap { $0 })
        }
    }

    func galleryController(_ controller: GalleryController, didSelectVideo video: Video) {
        // we don't support video
        wrapperDelegate?.galleryDidCancel()
    }

    func galleryController(_ controller: GalleryController, requestLightbox images: [Image]) {
        // do nothing
        return
    }

    func galleryControllerDidCancel(_ controller: GalleryController) {
        wrapperDelegate?.galleryDidCancel()
    }
}
