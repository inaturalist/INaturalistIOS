//
//  OnboardingReauthenticateViewController.swift
//  iNaturalist
//
//  Created by Alex Shepard on 9/12/22.
//  Copyright © 2022 iNaturalist. All rights reserved.
//

import Foundation
import UIKit

@objc
class OnboardingReauthenticateViewController: UIViewController {
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    
    @objc var loginAction: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        infoLabel.text = NSLocalizedString("You must re-authenticate to delete your account.", comment: "Reauthentication to delete account tip.")
        
        if let appDelegate = UIApplication.shared.delegate as? INaturalistAppDelegate,
           let login = appDelegate.loginController
        {
            usernameField.text = login.meUserLocal().login
            login.delegate = self
        }
        
        let cancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        navigationItem.rightBarButtonItem = cancel
        
        loginButton.setTitleColor(.inatTint(), for: .normal)
        
    }
    
    @objc func cancel(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @IBAction func loginButtonTapped(_ sender: UIButton) {
        if let appDelegate = UIApplication.shared.delegate as? INaturalistAppDelegate,
           let login = appDelegate.loginController
        {
            login.delegate = self
            login.login(withUsername: usernameField.text, password: passwordField.text)
        }
    }
}

extension OnboardingReauthenticateViewController: INatAuthenticationDelegate {
    func loginSuccess() {
        if let action = self.loginAction {
            action()
        }
    }
    
    func delayForSettingUpAccount() { }
    
    func loginFailedWithError(_ error: Error!) {
        let alertTitle = NSLocalizedString("Oops", comment: "Title error with oops text.")
        var alertMsg = NSLocalizedString("Failed to log in to iNaturalist. Please try again.", comment: "Unknown iNat login error")
        
        if let error = error as? NSError {
            if error.code == 401 {
                alertMsg = NSLocalizedString("Incorrect username or password.", comment: "Error msg when we get a 401 from the server")
            }
        }
        
        let alert = UIAlertController(title: alertTitle, message: alertMsg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        self.present(alert, animated: true)
    }
}
