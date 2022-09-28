//
//  NSDate+INaturalist.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/20/21.
//  Copyright © 2021 iNaturalist. All rights reserved.
//

#import "NSDate+INaturalist.h"

@implementation NSDate (INaturalist)

- (NSString *)inat_shortRelativeDateString {
    static NSRelativeDateTimeFormatter *dateFormatter = nil;
    if (!dateFormatter) {
        dateFormatter = [[NSRelativeDateTimeFormatter alloc] init];
        dateFormatter.dateTimeStyle = NSRelativeDateTimeFormatterStyleNumeric;
        dateFormatter.unitsStyle = NSRelativeDateTimeFormatterUnitsStyleShort;
    }
    
    NSTimeInterval timeSince = [self timeIntervalSinceNow];
    return [dateFormatter localizedStringFromTimeInterval:timeSince];
}

@end
