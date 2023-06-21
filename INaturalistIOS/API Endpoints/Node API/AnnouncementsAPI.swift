//
//  AnnouncementsAPI.swift
//  iNaturalist
//
//  Created by Alex Shepard on 6/13/23.
//  Copyright © 2023 iNaturalist. All rights reserved.
//

import Foundation

public final class AnnouncementsAPI: INatAPI {
    @objc public func announcementsForUser(done: @escaping INatAPIFetchCompletionCountHandler) {
        let path = "/v2/announcements";
        let query = "placement=mobile&fields=id,body,dismissible,start,placement"
        fetch(path, query: query, classMapping: ExploreAnnouncement.self, handler:done);
    }

    @objc public func dismissAnnouncement(id: Int, done: @escaping INatAPIFetchCompletionCountHandler) {
        let path = "/v2/announcements/\(id)/dismiss";
        put(path, query: nil, params: nil, classMapping: nil, handler: done);
    }
}

