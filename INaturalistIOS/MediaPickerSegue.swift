//
//  MediaPickerSegue.swift
//  iNaturalist
//
//  Created by Alex Shepard on 5/24/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

import UIKit

class MediaPickerSegue: UIStoryboardSegue {
   private var selfRetainer: MediaPickerSegue? = nil
   lazy var slideInTransitioningDelegate = SlideInPresentationManager()

   override func perform() {
      destination.transitioningDelegate = slideInTransitioningDelegate
      selfRetainer = self
      destination.modalPresentationStyle = .custom
      source.present(destination, animated: true, completion: nil)
   }
}
