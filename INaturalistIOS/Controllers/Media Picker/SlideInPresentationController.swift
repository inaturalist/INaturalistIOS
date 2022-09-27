//
//  SlideInPresentationController.swift
//  iNaturalist
//
//  Created by Alex Shepard on 5/24/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

import UIKit

class SlideInPresentationController: UIPresentationController {
    private var dimmingView: UIView!

    override init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?) {
        super.init(presentedViewController: presentedViewController, presenting: presentingViewController)
        setupDimmingView()
    }

    override func presentationTransitionWillBegin() {
        guard let dimmingView = dimmingView else { return }

        containerView?.insertSubview(dimmingView, at: 0)
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "V:|[dimmingView]|",
                                           options: [], metrics: nil, views: ["dimmingView": dimmingView]))
        NSLayoutConstraint.activate(
            NSLayoutConstraint.constraints(withVisualFormat: "H:|[dimmingView]|",
                                           options: [], metrics: nil, views: ["dimmingView": dimmingView]))

        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = 1.0
            return
        }

        coordinator.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 1.0
        })
    }

    override func dismissalTransitionWillBegin() {
        guard let coordinator = presentedViewController.transitionCoordinator else {
            dimmingView.alpha = 0.0
            return
        }

        coordinator.animate(alongsideTransition: { _ in
            self.dimmingView.alpha = 0.0
        })
    }

    override func containerViewWillLayoutSubviews() {
        presentedView?.frame = frameOfPresentedViewInContainerView
    }

    override func size(
        forChildContentContainer
        container: UIContentContainer,
        withParentContainerSize parentSize: CGSize
    ) -> CGSize {

        return CGSize(width: parentSize.width, height: 200.0)
    }

    override var frameOfPresentedViewInContainerView: CGRect {
        var frame: CGRect = .zero
        frame.size = size(
            forChildContentContainer: presentedViewController,
            withParentContainerSize: containerView!.bounds.size
        )
        frame.origin.y = containerView!.frame.height - 200.0
        return frame
    }
}

private extension SlideInPresentationController {
    func setupDimmingView() {
        dimmingView = UIView()
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        dimmingView.backgroundColor = UIColor(white: 0.0, alpha: 0.7)
        dimmingView.alpha = 0.0

        let recognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(recognizer:)))
        dimmingView.addGestureRecognizer(recognizer)
    }

    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        presentingViewController.dismiss(animated: true)
    }
}
