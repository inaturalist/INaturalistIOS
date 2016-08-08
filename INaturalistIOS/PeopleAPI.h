//
//  PeopleAPI.h
//  iNaturalist
//
//  Created by Alex Shepard on 8/2/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "INatAPI.h"

@class User;

@interface PeopleAPI : INatAPI

- (void)removeProfilePhotoForUser:(User *)user handler:(INatAPIFetchCompletionCountHandler)done;
- (void)uploadProfilePhoto:(UIImage *)image forUser:(User *)user handler:(INatAPIFetchCompletionCountHandler)done;
- (void)setUsername:(NSString *)username forUser:(User *)user handler:(INatAPIFetchCompletionCountHandler)done;

@end
