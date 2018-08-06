//
//  UserVisualization.h
//  iNaturalist
//
//  Created by Alex Shepard on 7/31/18.
//  Copyright © 2018 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol UserVisualization <NSObject>
- (NSInteger)userId;
- (NSString *)login;
- (NSString *)name;
- (NSURL *)userIcon;
- (NSString *)email;
- (NSInteger)observationsCount;
- (NSInteger)siteId;
- (NSURL *)userIconMedium;
@end
