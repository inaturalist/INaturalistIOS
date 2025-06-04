//
//  NSDate+INaturalist.h
//  iNaturalist
//
//  Created by Alex Shepard on 2/20/21.
//  Copyright © 2021 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (INaturalist)

- (NSString * _Nullable)inat_shortRelativeDateString;
- (NSString * _Nullable)inat_obscuredDateString;

@end

