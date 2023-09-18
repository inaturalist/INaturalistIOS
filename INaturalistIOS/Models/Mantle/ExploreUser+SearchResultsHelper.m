//
//  ExploreUser+SearchResultsHelper.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/11/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "ExploreUser+SearchResultsHelper.h"
#import "UIColor+ExploreColors.h"
#import "UIImage+INaturalist.h"

static UIImage *userIconPlaceholder;

@implementation ExploreUser (SearchResultsHelper)

- (NSString *)searchResult_Title {
    if (self.name)
        return self.name;
    else
        return self.login;
}

- (NSString *)searchResult_SubTitle {
    if (self.name)
        return self.login;
    else
        return nil;
}

- (NSURL *)searchResult_ThumbnailUrl {
    // eg http://www.inaturalist.org/attachments/users/icons/44845-thumb.jpg
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@/attachments/users/icons/%ld-thumb.jpg",
                                 INatMediaBaseURL, (long)self.userId]];
}

- (UIImage *)searchResult_PlaceholderImage {
    return [UIImage inat_defaultUserImage];
}

@end
