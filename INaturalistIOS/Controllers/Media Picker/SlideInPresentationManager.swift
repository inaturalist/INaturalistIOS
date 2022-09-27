//
//  SlideInPresentationManager.swift
//  iNaturalist
//
//  Created by Alex Shepard on 5/24/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

import UIKit

class SlideInPresentationManager: NSObject { }

extension SlideInPresentationManager: UIViewControllerTransitioningDelegate {
    func presentationController(
        forPresented presented: UIViewController,
        presenting: UIViewController?,
        source: UIViewController
    ) -> UIPresentationController? {

        let presentationController = SlideInPresentationController(
            presentedViewController: presented,
            presenting: presenting
        )
        return presentationController
    }
}
