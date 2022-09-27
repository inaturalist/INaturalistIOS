//
//  DownWrapper.swift
//  iNaturalist
//
//  Created by Alex Shepard on 5/18/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

import Foundation
import Down

extension String {
    func attributedString() -> NSAttributedString? {
        guard let data = self.data(using: String.Encoding.utf8,
                                   allowLossyConversion: false) else { return nil }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            NSAttributedString.DocumentReadingOptionKey.characterEncoding: String.Encoding.utf8.rawValue,
            NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html
        ]
        let htmlString = try? NSMutableAttributedString(data: data, options: options, documentAttributes: nil)

        return htmlString
    }
}

@objc class DownWrapper: NSObject {
    @objc public func markdownToAttributedString(markdownStr: NSString, css: NSString) -> NSAttributedString {
        let down = Down(markdownString: markdownStr as String)

        do {
            let html = try down.toHTML([.unsafe, .hardBreaks])
            let htmlWithStyles = "<style>" + (css as String) + "</style>" + html
            return htmlWithStyles.attributedString() ?? NSAttributedString()
        } catch {
            print(error)
            return NSAttributedString()
        }
    }
}
