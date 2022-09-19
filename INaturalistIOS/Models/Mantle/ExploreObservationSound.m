//
//  ExploreObservationSound.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/3/21.
//  Copyright © 2021 iNaturalist. All rights reserved.
//

#import "ExploreObservationSound.h"

@implementation ExploreObservationSound

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        // file URL has a specific meaning in iOS that isn't relevant here, so rename the field
        @"mediaUrlString": @"sound.file_url",
        @"observationSoundId": @"id",
        @"uuid": @"uuid",
    };
}

- (NSString *)mediaKey {
    return nil;
}

- (NSURL *)mediaUrl {
    return [NSURL URLWithString:self.mediaUrlString];
}

@end
