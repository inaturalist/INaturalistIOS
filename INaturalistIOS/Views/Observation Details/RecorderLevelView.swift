//
//  RecorderLevelView.swift
//  iNaturalist
//
//  Created by Alex Shepard on 9/27/22.
//  Copyright © 2022 iNaturalist. All rights reserved.
//

import UIKit

class RecorderLevelView: UIView {
    public var level: Float = 0.0 {
        didSet {
            // clamped to { 0.0, 1.0 }
            if level < 0.0 { level = 0.0 }
            if level > 1.0 { level = 1.0 }

            let baseString = NSLocalizedString(
                "Recording Level (from 0 to 1)",
                comment: "Accessibility label for sound recorder"
            )
            self.accessibilityLabel = String(format: baseString, level)
            self.accessibilityValue = "\(level)"

            let scaledLevel = level * 30
            // anything less than 0.01 is basically nothing
            if scaledLevel < 0.01 { return }
            for level in 0..<30 {
                DispatchQueue.main.async {
                    if level <= Int(scaledLevel) {
                        self.levelViews[level].backgroundColor = .green
                    } else {
                        self.levelViews[level].backgroundColor = .black
                    }
                }
            }
        }
    }

    var levelViews = [UIView]()

    override init(frame: CGRect) {
        super.init(frame: frame)

        for _ in 0..<30 {
            let levelView = UIView(frame: .zero)
            levelView.backgroundColor = .black
            levelViews.append(levelView)
        }

        let stack = UIStackView(arrangedSubviews: levelViews)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.distribution = .fillEqually
        stack.axis = .horizontal
        stack.spacing = 2
        stack.alignment = .center

        self.addSubview(stack)

        for levelView in levelViews {
            NSLayoutConstraint.activate([
                levelView.widthAnchor.constraint(equalToConstant: 20),
                levelView.heightAnchor.constraint(equalToConstant: 40),
                levelView.centerYAnchor.constraint(equalTo: stack.centerYAnchor)
            ])
        }

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
            stack.topAnchor.constraint(equalTo: self.topAnchor),
            stack.bottomAnchor.constraint(equalTo: self.bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        fatalError("Interface Builder is not supported!")
    }
}
