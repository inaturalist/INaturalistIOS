//
//  Bundle_VersionString.swift
//  iNaturalist
//
//  Created by Alex Shepard on 8/9/23.
//  Copyright © 2023 iNaturalist. All rights reserved.
//

import Foundation

extension Bundle {
    @objc func versionString() -> String {
        if let info = self.infoDictionary {
            let bundleName = info["CFBundleName"] ?? "unknown app"
            let buildNumber = info["CFBundleVersion"] ?? "unknown build"
            let appVersion = info["CFBundleShortVersionString"] ?? "unknown version"
            let systemVersion = UIDevice.current.systemVersion
            return "\(bundleName) version \(appVersion), build \(buildNumber), iOS \(systemVersion)"
        } else {
            return "unknown version info"
        }
    }
}
