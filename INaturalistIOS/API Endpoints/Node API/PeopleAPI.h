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

- (void)setSiteId:(NSInteger)siteId forUserId:(NSInteger)userId handler:(INatAPIFetchCompletionCountHandler)done;
- (void)setPrefersNoTracking:(BOOL)preference forUserId:(NSInteger)userId handler:(INatAPIFetchCompletionCountHandler)done;
- (void)setPrefersShowCommonNames:(BOOL)preference forUserId:(NSInteger)userId handler:(INatAPIFetchCompletionCountHandler)done;
- (void)setPrefersShowScientificNamesFirst:(BOOL)preference forUserId:(NSInteger)userId handler:(INatAPIFetchCompletionCountHandler)done;
- (void)setPiConsent:(BOOL)piConsent dtConsent:(BOOL)dtConsent forUserId:(NSInteger)userId handler:(INatAPIFetchCompletionCountHandler)done;

- (void)createUserEmail:(NSString *)email
                  login:(NSString *)login
               password:(NSString *)password
                 siteId:(NSInteger)siteId
                license:(NSString *)license
              localeStr:(NSString *)localeStr
                handler:(INatAPIFetchCompletionCountHandler)done;

@end
