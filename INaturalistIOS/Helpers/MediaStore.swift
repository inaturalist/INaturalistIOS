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
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0].appendingPathComponent("sounds")
    }

    
    @objc public func cleanupStore(validMediaKeys: [String], syncedMediaKeys: [String], allowedTime: TimeInterval) {
        let beginCleanupDate = Date()
                
        do {
            let allSoundFiles = try FileManager().contentsOfDirectory(atPath: self.getDocumentsDirectory().path)
            for soundFile in allSoundFiles {
                let now = Date()
                let timeCleaningSoFar = now.timeIntervalSince(beginCleanupDate)
                if (timeCleaningSoFar >= allowedTime) {
                    break
                }
                
                // trim .m4a off the end to get the key
                let mediaKey = soundFile.replacingOccurrences(of: ".m4a", with: "")
                
                // sanity check
                if (mediaKey.count != 36) { break }
                
                let filePath = self.getDocumentsDirectory().appendingPathComponent(soundFile).path

                // don't delete anything less than 24 hours old - should make sure if
                // you start an obs, then close and reopen the app to do something else,
                // we don't delete the photo for the in-progress observation. basically, the
                // obs photo may not have been inserted into realm yet, so it's not safe
                // to just delete it.
                let attrs = try FileManager().attributesOfItem(atPath: filePath)
                if let creationDate = attrs[FileAttributeKey.creationDate] as? Date {
                    let since = Date().timeIntervalSince(creationDate)
                    if (since < 60 * 60 * 24) { break }
                } else {
                    // no creation date, break
                    break
                }
                
                if (!validMediaKeys.contains(mediaKey)) {
                    // safe to delete this file, since we don't have
                    // an observation sound for it
                    try FileManager().removeItem(atPath: filePath)
                }
                
                if (syncedMediaKeys.contains(mediaKey)) {
                    // safe to delete this file, since it's been synced
                    // to the server and we can play it back over the internet
                    try FileManager().removeItem(atPath: filePath)
                }
            }
        } catch {
            return
        }
    }
}
