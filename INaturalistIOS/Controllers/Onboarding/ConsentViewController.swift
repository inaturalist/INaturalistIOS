//
//  ConsentViewController.swift
//  iNaturalist
//
//  Created by Alex Shepard on 6/1/22.
//  Copyright © 2022 iNaturalist. All rights reserved.
//

import UIKit

@objc
class ConsentViewController: UIViewController {
    @objc public var user: ExploreUserRealm?

    private var piConsentView: ConsentView?
    private var dtConsentView: ConsentView?

    private let peopleApi = PeopleAPI()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = NSLocalizedString("Privacy", comment: "title for consent screen")

        let learnMore = NSLocalizedString("Learn More", comment: "button to learn more about inat account policies")
        let viewPrivacyPolicy = NSLocalizedString("View Privacy Policy", comment: "button to view privacy policy")
        let viewTermsOfUse = NSLocalizedString("View Terms of Use", comment: "button to view terms of use")

        let piConsentLabelText = NSLocalizedString(
            // swiftlint:disable:next line_length
            "I consent to allow iNaturalist to store and process limited kinds of personal information about me in order to manage my account.",
            comment: "personal info consent checkbox label"
        )

        self.piConsentView = ConsentView(
            labelText: piConsentLabelText,
            learnMoreText: learnMore,
            userConsent: user?.piConsent ?? false
        ) {
            let alertTitle = NSLocalizedString(
                "Personal Information",
                comment: "Title for About Personal Information notice during signup"
            )
            let piMessage = NSLocalizedString(
                // swiftlint:disable:next line_length
                "We store personal information like usernames and email addresses in order to manage accounts on this site, and to comply with privacy laws, we need you to check this box to indicate that you consent to this use of personal information. To learn more about what information we collect and how we use it, please see our Privacy Policy and our Terms of Use. There is no way to have an iNaturalist account without storing personal information, so the only way to revoke this consent is to delete your account.",
                comment: "Alert text for the personal information checkbox during create account."
            )

            let alert = UIAlertController(title: alertTitle, message: piMessage, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: viewPrivacyPolicy, style: .default, handler: { _ in
                if let privacyUrl = URL(string: "https://www.inaturalist.org/pages/privacy") {
                    UIApplication.shared.open(privacyUrl, options: [:], completionHandler: nil)
                }
            }))
            alert.addAction(UIAlertAction(title: viewTermsOfUse, style: .default, handler: { _ in
                if let privacyUrl = URL(string: "https://www.inaturalist.org/pages/terms") {
                    UIApplication.shared.open(privacyUrl, options: [:], completionHandler: nil)
                }
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))

            self.present(alert, animated: true)
        }

        let dtConsentLabelText = NSLocalizedString(
            "I consent to allow my personal information to be transferred to the United States of America.",
            comment: "data transfer consent checkbox label"
        )
        self.dtConsentView = ConsentView(
            labelText: dtConsentLabelText,
            learnMoreText: learnMore,
            userConsent: user?.dataTransferConsent ?? false
        ) {
            let alertTitle = NSLocalizedString(
                "Personal Information",
                comment: "Title for About Personal Information notice during signup"
            )
            let dtMessage = NSLocalizedString(
                // swiftlint:disable:next line_length
                "Some data privacy laws, like the European Union's General Data Protection Regulation (GDPR), require explicit consent to transfer personal information from their jurisdictions to other jurisdictions where the legal protection of this information is not considered adequate. As of 2020, the European Union no longer considers the United States to be a jurisdiction that provides adequate legal protection of personal information, specifically because of the possibility of the US government surveilling data entering the US. It is possible other jurisdictions may have the same opinion. Using iNaturalist requires the storage of personal information like your email address, all iNaturalist data is stored in the United States, and we cannot be sure what legal jurisdiction you are in when you are using iNaturalist, so in order to comply with privacy laws like the GDPR, you must acknowledge that you understand and accept this risk and consent to transferring your personal information to iNaturalist's servers in the US. To learn more about what information we collect and how we use it, please see our Privacy Policy and our Terms of Use. There is no way to have an iNaturalist account without storing personal information, so the only way to revoke this consent is to delete your account.",
                comment: "Alert text for the data transfer consent checkbox during create account."
            )

            let alert = UIAlertController(title: alertTitle, message: dtMessage, preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: viewPrivacyPolicy, style: .default, handler: { _ in
                if let privacyUrl = URL(string: "https://www.inaturalist.org/pages/privacy") {
                    UIApplication.shared.open(privacyUrl, options: [:], completionHandler: nil)
                }
            }))
            alert.addAction(UIAlertAction(title: viewTermsOfUse, style: .default, handler: { _ in
                if let privacyUrl = URL(string: "https://www.inaturalist.org/pages/terms") {
                    UIApplication.shared.open(privacyUrl, options: [:], completionHandler: nil)
                }
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))

            self.present(alert, animated: true)
        }

        let doneButton = UIButton()
        doneButton.setTitle(NSLocalizedString("Done", comment: "title for done button"), for: .normal)
        doneButton.setTitleColor(.systemBlue, for: .normal)
        doneButton.addTarget(self, action: #selector(done), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [self.piConsentView!, self.dtConsentView!, doneButton])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 40

        self.view.addSubview(stack)

        stack.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        stack.centerYAnchor.constraint(equalTo: self.view.centerYAnchor).isActive = true
        stack.widthAnchor.constraint(equalTo: self.view.widthAnchor, constant: -40).isActive = true

        // match the color in the onboarding flow
        self.view.backgroundColor = UIColor(red: 0.94, green: 0.94, blue: 0.94, alpha: 1.00)
    }

    @objc func done(_ button: UIButton) {
        guard let piConsentView = piConsentView,
              let dtConsentView = dtConsentView,
              let user = user else {
            // i guess dismiss and return?
            self.dismiss(animated: true)
            return
        }

        if !piConsentView.userConsent {
            let alertText = NSLocalizedString(
                "There is no way to have an iNaturalist account without storing personal information.",
                comment: "Error for no personal info consent when making account."
            )

            let alert = UIAlertController(title: alertText, message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
            self.present(alert, animated: true)

            return
        }

        if !dtConsentView.userConsent {
            let alertText = NSLocalizedString(
                // swiftlint:disable:next line_length
                "There is no way to have an iNaturalist account without storing personal information in the United States.",
                comment: "Error for no data transfer consent consent when making account."
            )

            let alert = UIAlertController(title: alertText, message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: ""), style: .default))
            self.present(alert, animated: true)

            return
        }

        let realm = RLMRealm.defaultRealm(for: DispatchQueue.main)
        realm.beginWriteTransaction()
        user.piConsent = piConsentView.userConsent
        user.dataTransferConsent = dtConsentView.userConsent

        do {
            try realm.commitWriteTransaction()

            self.peopleApi.setPiConsent(
                piConsentView.userConsent,
                dtConsent: dtConsentView.userConsent,
                forUserId: user.userId
            ) { _, _, _ in
                self.dismiss(animated: true)
            }
        } catch { }
    }
}
