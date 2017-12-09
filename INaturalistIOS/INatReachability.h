//
//  INatReachability.h
//  iNaturalist
//
//  Created by Alex Shepard on 12/9/17.
//  Copyright © 2017 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface INatReachability : NSObject
+ (INatReachability *)sharedClient;
- (BOOL)isNetworkReachable;
@end
