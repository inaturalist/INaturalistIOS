//
//  ExploreUser+SearchResultsHelper.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/11/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <FontAwesomeKit/FAKIonIcons.h>

#import "ExploreUser+SearchResultsHelper.h"
#import "UIColor+ExploreColors.h"

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
    if (!userIconPlaceholder) {
        FAKIcon *person = [FAKIonIcons iosPersonIconWithSize:30.0f];
        [person addAttribute:NSForegroundColorAttributeName value:[UIColor inatBlack]];
        userIconPlaceholder = [person imageWithSize:CGSizeMake(30.0f, 30.0f)];
    }
    
    return userIconPlaceholder;
}

@end
