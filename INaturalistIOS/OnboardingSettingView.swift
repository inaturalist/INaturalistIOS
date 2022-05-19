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
    var labelAction: () -> ()
    var consentChangeAction: () -> ()

    
    var switcher: UISwitch!
            
    @objc init(labelText: String, userConsent: Bool, labelAction: @escaping () -> (), consentChangeAction: @escaping () -> ()) {
        self.labelText = labelText
        self.userConsent = userConsent
        self.labelAction = labelAction
        self.consentChangeAction = consentChangeAction
        
        super.init(frame: .zero)
        
        self.switcher = UISwitch(frame: .zero)
        self.switcher.translatesAutoresizingMaskIntoConstraints = false
        self.switcher.widthAnchor.constraint(equalToConstant: 50).isActive = true
        self.switcher.isOn = self.userConsent
        self.switcher.addTarget(self, action: #selector(switched), for: .valueChanged)
        
        let label = UILabel(frame: .zero)
        label.text = labelText
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 13)
                
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        label.addGestureRecognizer(tap)
        label.isUserInteractionEnabled = true
        
        let hstack = UIStackView(arrangedSubviews: [switcher, label])
        hstack.translatesAutoresizingMaskIntoConstraints = false
        hstack.distribution = .fill
        hstack.spacing = 20
        hstack.alignment = .top
        
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
    
    @objc func tapped(recognizer: UITapGestureRecognizer) {
        self.labelAction()
    }
    
    @objc func switched(sender: UISwitch) {
        self.userConsent = sender.isOn
        self.consentChangeAction()
    }
}
