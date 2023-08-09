//
//  LoadingViewController.swift
//  iNaturalist
//
//  Created by Alex Shepard on 8/8/23.
//  Copyright © 2023 iNaturalist. All rights reserved.
//

import UIKit
import MessageUI

import JDStatusBarNotification
import UIColor_HTMLColors
import Realm

class LoadingViewController: UIViewController {
    let launchImageView = UIImageView(frame: .zero)
    let statusLabel = UILabel(frame: .zero)
    let spinner = UIActivityIndicatorView(frame: .zero)

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.backgroundColor = .inatTint()

        configureGlobalStyles()

        launchImageView.image = UIImage(named: "inat-white-logo")
        launchImageView.contentMode = .scaleAspectFit

        statusLabel.text = "Updating database..."
        statusLabel.textColor = .white
        statusLabel.numberOfLines = 0

        if #available(iOS 13.0.0, *) {
            spinner.style = .large
            spinner.color = .white
        } else {
            spinner.style = .white
        }
        
        spinner.startAnimating()
        spinner.hidesWhenStopped = true

        let stack = UIStackView(arrangedSubviews: [launchImageView, statusLabel, spinner])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 50
        stack.alignment = .center
        stack.distribution = .equalSpacing
        self.view.addSubview(stack)

        stack.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 15).isActive = true
        stack.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -15).isActive = true
        stack.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
    }


    override func viewDidAppear(_ animated: Bool) {

    }

    func configureGlobalStyles() {
        UITabBar.appearance().barStyle = .default
        UINavigationBar.appearance().barStyle = .default
        UISearchBar.appearance().barStyle = .default

        UINavigationBar.appearance().tintColor = .inatTint()
        UIBarButtonItem.appearance().tintColor = .inatTint()
        UISegmentedControl.appearance().tintColor = .inatTint()
        UITabBar.appearance().tintColor = .inatTint()

        UITabBarItem.appearance().setTitleTextAttributes([.foregroundColor: UIColor.inatTint()!], for: .selected)
        UITabBarItem.appearance().setTitleTextAttributes([.foregroundColor: UIColor.inatInactiveGreyTint()!], for: .normal)

        JDStatusBarNotification.setDefaultStyle { style in
            style?.barColor = UIColor(hexString: "#969696")
            style?.textColor = .white
            return style
        }
    }

    @objc func alert(error: NSError) {
        let alert = UIAlertController(title: "Error", message: "There was an error launching iNaturalist", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Contact iNat Support", style: .default) { action in
            self.dismiss(animated: true, completion: {
                self.contactSupport(error: error)
            })
        }
        alert.addAction(okAction)

        let updateAction = UIAlertAction(title: "Delete Local Database and Try Again", style: .destructive) { action in
            self.deleteDatabase()
        }
        alert.addAction(updateAction)

        self.present(alert, animated: true)
    }

    func contactSupport(error: NSError) {
        let supportEmailAddress = "help@inaturalist.org"
        let subject = "iPhone App Crash At Launch"

        if MFMailComposeViewController.canSendMail() {
            let composeVC = MFMailComposeViewController()

            var versionText = "unknown version info"
            if let info = Bundle.main.infoDictionary {
                let buildNumber = info["CFBundleVersion"] ?? "unknown build"
                let appVersion = info["CFBundleShortVersionString"] ?? "unknown version"
                let systemVersion = UIDevice.current.systemVersion
                versionText = "app version \(appVersion), build \(buildNumber), iOS \(systemVersion)"
            }

            composeVC.mailComposeDelegate = self
            composeVC.setToRecipients([ supportEmailAddress ])
            composeVC.setSubject(subject)

            let body = "\(error.localizedDescription)\n\(error.localizedFailureReason ?? "")\n\(error.localizedRecoveryOptions ?? [""])\n\(error.localizedRecoverySuggestion ?? "")\n\n\(versionText)"

            composeVC.setMessageBody(body, isHTML: false)

            if let realmUrl = RLMRealmConfiguration.default().fileURL,
               let data = try? Data(contentsOf: realmUrl)
            {
                composeVC.addAttachmentData(data, mimeType: "application/data", fileName: "db.realm")
            }

            self.present(composeVC, animated: true)
        } else {
            self.statusLabel.text = "Can't send crash support email - please contact help@inaturalist.org."
            spinner.stopAnimating()
        }
    }

    func deleteDatabase() {
        if let realmURL = Realm.RLMRealmConfiguration.default().fileURL {
            let realmURLs = [
                realmURL,
                realmURL.appendingPathComponent("lock"),
                realmURL.appendingPathExtension("note"),
                realmURL.appendingPathExtension("management"),
            ]

            for url in realmURLs {
                do {
                    try FileManager.default.removeItem(at: url)
                } catch let error {
                    statusLabel.text = "Failed to delete \(url): \(error.localizedDescription). Please contact help@inaturalist.org."
                }
            }

            if let appDelegate = UIApplication.shared.delegate as? INaturalistAppDelegate,
               let login = appDelegate.loginController
            {
                if login.isLoggedIn {
                    appDelegate.showInitialSignupUI()
                } else {
                    appDelegate.showMainUI()
                }
            } else {
                statusLabel.text = "App is fatally misconfigured. Please contact help@inaturalist.org"
            }
        } else {
            statusLabel.text = "Can't find realm database. Please contact help@inaturalist.org"
        }
    }
}

extension LoadingViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {

        if result == .sent {
            self.statusLabel.text = "Thank you for contacting iNat support. We'll get back to you as soon as we can."
        } else {
            self.statusLabel.text = "You can contact help@inaturalist.org for more help with this issue."
        }

        spinner.stopAnimating()

        controller.dismiss(animated: true)
    }
}

