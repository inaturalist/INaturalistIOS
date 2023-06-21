//
//  ExploreAnnouncement.h
//  iNaturalist
//
//  Created by Alex Shepard on 6/13/23.
//  Copyright © 2023 iNaturalist. All rights reserved.
//

@import Mantle;


@interface ExploreAnnouncement : MTLModel <MTLJSONSerializing>

@property NSInteger announcementId;
@property NSString *body;
@property NSDate *startDate;
@property BOOL dismissible;
@property NSString *placement;

@end
