//
//  ExploreLocation+SearchResultsHelper.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/11/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "ExploreLocation+SearchResultsHelper.h"

@implementation ExploreLocation (SearchResultsHelper)

- (NSString *)searchResult_Title {
    return self.name;
}

@end
