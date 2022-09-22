//
//  PeopleRailsAPI.m
//  iNaturalist
//
//  Created by Alex Shepard on 8/25/22.
//  Copyright © 2022 iNaturalist. All rights reserved.
//

#import "PeopleRailsAPI.h"
#import "Analytics.h"

@implementation PeopleRailsAPI

- (void)deleteAccountForUserId:(NSInteger)userId confirmationCode:(NSString *)code confirmation:(NSString *)confirmation done:(INatAPIFetchCompletionCountHandler)done {
    [[Analytics sharedClient] debugLog:@"Network - delete user account via rails"];
    NSString *path = [NSString stringWithFormat:@"/users/%ld.json", userId];
    NSString *query = [NSString stringWithFormat:@"confirmation_code=%@&confirmation=%@",
                       code, confirmation];
    [self delete:path query:query handler:done];

}

@end
