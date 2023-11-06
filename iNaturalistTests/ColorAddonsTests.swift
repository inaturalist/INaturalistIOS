//
//  ColorAddonsTests.swift
//  iNaturalistTests
//
//  Created by Alex Shepard on 11/6/23.
//  Copyright © 2023 iNaturalist. All rights reserved.
//

import XCTest

final class ColorAddonsTests: XCTestCase {
    func testInatTint() throws {
        guard let color = UIColor.inatTint() else {
            XCTAssert(false, "Can't get inat tint")
            return
        }

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        XCTAssertEqual(red, 0.4549, accuracy: 0.0001, "Bad red value for iNat tint")
        XCTAssertEqual(green, 0.6745, accuracy: 0.0001, "Bad green value for iNat tint")
        XCTAssertEqual(blue, 0.0, accuracy: 0.0001, "Bad blue value for iNat tint")
    }


}
