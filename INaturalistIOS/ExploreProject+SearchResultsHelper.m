//
//  ExploreProject+SearchResultsHelper.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/11/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "ExploreProject+SearchResultsHelper.h"

@implementation ExploreProject (SearchResultsHelper)

- (NSString *)searchResult_Title {
    return self.title;
}

- (NSString *)searchResult_SubTitle {
    return @"";
}

- (NSURL *)searchResult_ThumbnailUrl {
    return [NSURL URLWithString:self.iconUrl];
}

- (UIImage *)searchResult_PlaceholderImage {
    return [UIImage imageNamed:@"ic_unknown"];
}

@end
