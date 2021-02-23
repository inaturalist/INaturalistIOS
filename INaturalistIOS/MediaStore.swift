//
//  MediaStore.swift
//  iNaturalist
//
//  Created by Alex Shepard on 2/3/21.
//  Copyright © 2021 iNaturalist. All rights reserved.
//

import UIKit

@objc final class MediaStore: NSObject {
    
    override init() {
        super.init()
        
        if !FileManager.default.fileExists(atPath: getDocumentsDirectory().path) {
            do {
                try FileManager.default.createDirectory(at: getDocumentsDirectory(), withIntermediateDirectories: true, attributes: nil)
            } catch (let error) {
                print("FAILED creating sounds dir: \(error)")
            }
        }
    }
    
    @objc public func mediaPathForKey(_ key: String) -> String {
        return getDocumentsDirectory().appendingPathComponent("\(key).m4a").path
    }
    
    @objc public func mediaUrlForKey(_ key: String) -> URL {
        return getDocumentsDirectory().appendingPathComponent("\(key).m4a")
    }
    
    @objc func destroyMediaKey(_ key: String) {
        print("destroy")
    }
        
    @objc public func cleanupMediaStore(unsyncedMediaKeys: [String]) {
        print("Cleanup media store")
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("sounds")
    }


}
