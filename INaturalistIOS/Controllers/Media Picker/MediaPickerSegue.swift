//
//  MediaPickerSegue.swift
//  iNaturalist
//
//  Created by Alex Shepard on 5/24/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

import UIKit

class MediaPickerSegue: UIStoryboardSegue {
    private var selfRetainer: MediaPickerSegue?
    lazy var slideInTransitioningDelegate = SlideInPresentationManager()

    override func perform() {
        destination.transitioningDelegate = slideInTransitioningDelegate
        // hold a strong reference to self so that the the transitioning delegate
        // doesn't get dealloced while we're running the dismiss animation(s)
        selfRetainer = self
        destination.modalPresentationStyle = .custom
        source.present(destination, animated: true, completion: nil)
    }
}
