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

- (void)removeProfilePhotoForUserId:(NSInteger)userId handler:(INatAPIFetchCompletionCountHandler)done;
- (void)uploadProfilePhoto:(UIImage *)image forUserId:(NSInteger)userId handler:(INatAPIFetchCompletionCountHandler)done;
- (void)setUsername:(NSString *)username forUserId:(NSInteger)userId handler:(INatAPIFetchCompletionCountHandler)done;
- (void)fetchMeHandler:(INatAPIFetchCompletionCountHandler)done;
- (void)setEmailAddress:(NSString *)email forUserId:(NSInteger)userId handler:(INatAPIFetchCompletionCountHandler)done;

@end
