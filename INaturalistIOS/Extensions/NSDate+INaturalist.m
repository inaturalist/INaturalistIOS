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
    if (@available(iOS 13.0, *)) {
        static NSRelativeDateTimeFormatter *dateFormatter = nil;
        if (!dateFormatter) {
            dateFormatter = [[NSRelativeDateTimeFormatter alloc] init];
            dateFormatter.dateTimeStyle = NSRelativeDateTimeFormatterStyleNumeric;
            dateFormatter.unitsStyle = NSRelativeDateTimeFormatterUnitsStyleShort;
        }
        
        NSTimeInterval timeSince = [self timeIntervalSinceNow];
        return [dateFormatter localizedStringFromTimeInterval:timeSince];
    } else {
        // Fallback on earlier versions
        static NSDateFormatter *dateFormatter = nil;
        if (!dateFormatter) {
            dateFormatter = [[NSDateFormatter alloc] init];
            dateFormatter.locale = [NSLocale currentLocale];
            dateFormatter.timeStyle = NSDateFormatterNoStyle;
            dateFormatter.dateStyle = NSDateFormatterShortStyle;
        }
        
        return [dateFormatter stringFromDate:self];
    }
}

- (NSString *)inat_obscuredDateString {
    static NSDateFormatter *obscuredFormatter = nil;
    if (!obscuredFormatter) {
        obscuredFormatter = [[NSDateFormatter alloc] init];
        [obscuredFormatter setLocalizedDateFormatFromTemplate:@"YYYYMMM"];
    }

    return [obscuredFormatter stringFromDate:self];
}


@end
