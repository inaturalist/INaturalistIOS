//
//  ForgotPasswordController.swift
//  iNaturalist
//
//  Created by Alex Shepard on 6/30/21.
//  Copyright © 2021 iNaturalist. All rights reserved.
//

import Foundation
import UIKit
import WebKit

@objc protocol ForgotPasswordDelegate {
    func finished(forgotPasswordController: ForgotPasswordController)
}

class ForgotPasswordController: UIViewController {
    let webView = WKWebView()
    let activity = UIActivityIndicatorView(style: .gray)
    var isPostingEmailAddress = false
    
    @objc public weak var delegate: ForgotPasswordDelegate?
    
    func load(_ url: URL) {
        let request = URLRequest(url: url)
        webView.load(request)
        
        activity.isHidden = false
        activity.startAnimating()
        activity.hidesWhenStopped = true
    }
    
    override func loadView() {
        self.view = webView
        
        webView.navigationDelegate = self
        let activityButton = UIBarButtonItem(customView: activity)
        self.navigationItem.rightBarButtonItem = activityButton
        
        if let url = URL(string: "https://www.inaturalist.org/forgot_password.mobile") {
            self.load(url)
        }
    }
}

extension ForgotPasswordController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        activity.stopAnimating()
    }
        
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        if navigationAction.request.httpMethod == "POST" {
            isPostingEmailAddress = true
        }
        
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        
        if let response = navigationResponse.response as? HTTPURLResponse {
            if isPostingEmailAddress && response.statusCode > 199 && response.statusCode < 400 {
                decisionHandler(.cancel)
                self.delegate?.finished(forgotPasswordController: self)
                return
            }
        }

        decisionHandler(.allow)
    }
}
