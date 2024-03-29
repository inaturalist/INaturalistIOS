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
        
        statusLabel.text = NSLocalizedString("Updating database...", comment: "Title for progress view when migrating db")
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
        let errorTitle = NSLocalizedString("Error", comment: "Title for error alert")
        let errorMessage = NSLocalizedString("There was an error launching iNaturalist", comment: "Message when app fails to launch, the alert will have recovery suggestions")
        let alert = UIAlertController(title: errorTitle, message: errorMessage, preferredStyle: .alert)

        let contactSupport = NSLocalizedString("Contact Support", comment: "Button to contact support when app has failed to launch.")
        let okAction = UIAlertAction(title: contactSupport, style: .default) { action in
            self.dismiss(animated: true, completion: {
                self.contactSupport(error: error)
            })
        }
        alert.addAction(okAction)

        let deleteDb = NSLocalizedString("Delete Local Database and Try Again", comment: "Button to delete the database. This will appear in red as a destructive action.")
        let updateAction = UIAlertAction(title: deleteDb, style: .destructive) { action in
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

            let versionText = Bundle.main.versionString()

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

            self.statusLabel.text = NSLocalizedString("Can't send crash support email - please contact help@inaturalist.org.", comment: "Status message when email is not configured on the phone so we can't send email on a user's behalf.")
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
                } catch {
                    self.statusLabel.text = NSLocalizedString("Failed to delete database. Please contact help@inaturalist.org.", comment: "Status message when the user tries to delete the DB but it fails.")
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
                statusLabel.text = NSLocalizedString("App is fatally misconfigured. Please contact help@inaturalist.org.", comment: "Status message when the database is unavailable and large parts of the app aren't working. Shouldn't happen, but fallback in case it ever does.")
            }
        } else {
            statusLabel.text = NSLocalizedString("Can't find realm database, can't continue. Please contact help@inaturalist.org.", comment: "Status message when the app can't start due to a corrupt database but the database doesn't exist. Shouldn't happen, but fallback in case it ever does.")
        }
    }
}

extension LoadingViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {

        if result == .sent {
            self.statusLabel.text = NSLocalizedString("Thank you for contacting iNat support. We'll get back to you as soon as we can.", comment: "Status message after a user sends info to iNat support after the database crashes early on launch.")
        } else {
            self.statusLabel.text = NSLocalizedString("Didn't send crash support email - please contact help@inaturalist.org.", comment: "Status message when the user tapped contact support but then chose to not allow us to send a support email on their behalf.")
        }

        spinner.stopAnimating()

        controller.dismiss(animated: true)
    }
}

