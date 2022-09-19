//
//  PeopleRailsAPI.h
//  iNaturalist
//
//  Created by Alex Shepard on 8/25/22.
//  Copyright © 2022 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "INatRailsAPI.h"

@interface PeopleRailsAPI : INatRailsAPI

- (void)deleteAccountForUserId:(NSInteger)userId confirmationCode:(NSString *)code confirmation:(NSString *)confirmation done:(INatAPIFetchCompletionCountHandler)done;

@end

