//
//  OnboardingSettingView.swift
//  iNaturalist
//
//  Created by Alex Shepard on 5/18/22.
//  Copyright © 2022 iNaturalist. All rights reserved.
//

import UIKit

class ConsentView: UIView {
    @objc public var userConsent: Bool
    var labelText: String
    var learnMoreText: String
    var learnMoreAction: () -> ()
    var consentChangeAction: () -> ()
    
    var switcher: UISwitch!
            
    @objc init(labelText: String, learnMoreText: String, userConsent: Bool, learnMoreAction: @escaping () -> (), consentChangeAction: @escaping () -> ()) {
        self.labelText = labelText
        self.learnMoreText = learnMoreText
        self.userConsent = userConsent
        self.learnMoreAction = learnMoreAction
        self.consentChangeAction = consentChangeAction
        
        super.init(frame: .zero)
        
        self.switcher = UISwitch(frame: .zero)
        self.switcher.translatesAutoresizingMaskIntoConstraints = false
        self.switcher.widthAnchor.constraint(equalToConstant: 50).isActive = true
        self.switcher.isOn = self.userConsent
        self.switcher.addTarget(self, action: #selector(switched), for: .valueChanged)
        
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = labelText
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 13)
        
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(self.learnMoreText, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 13)
        button.addTarget(self, action: #selector(tappedLearnMore), for: .touchUpInside)
        button.titleLabel?.textColor = .black
        button.setTitleColor(.black, for: .normal)
        
        let vstack = UIStackView(arrangedSubviews: [label, button])
        vstack.axis = .vertical
        vstack.alignment = .leading
        vstack.translatesAutoresizingMaskIntoConstraints = false
        
        let hstack = UIStackView(arrangedSubviews: [switcher, vstack])
        hstack.translatesAutoresizingMaskIntoConstraints = false
        hstack.distribution = .fill
        hstack.spacing = 20
        hstack.alignment = .top
        hstack.axis = .horizontal
        
        self.addSubview(hstack)
        hstack.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        hstack.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        hstack.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        hstack.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
    }
    
    override init(frame: CGRect) {
        fatalError("init(frame:) has not been implemented")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func tappedLearnMore(button: UIButton) {
        self.learnMoreAction()
    }
    
    @objc func switched(sender: UISwitch) {
        self.userConsent = sender.isOn
        self.consentChangeAction()
    }
}
