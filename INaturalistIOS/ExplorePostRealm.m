//
//  ExplorePostRealm.m
//  iNaturalist
//
//  Created by Alex Shepard on 10/29/18.
//  Copyright © 2018 iNaturalist. All rights reserved.
//

#import "ExplorePostRealm.h"
#import "NSURL+INaturalist.h"

@implementation ExplorePostRealm

- (instancetype)initWithMantleModel:(ExplorePost *)model {
    if (self = [super init]) {
        self.postId = model.postId;
        self.body = model.body;
        self.excerpt = model.excerpt;
        self.publishedAt = model.publishedAt;
        self.title = model.title;
        self.coverImageUrlString = model.coverImageUrl.absoluteString;
        
        self.parentId = model.parentId;
        self.parentType = model.parentType;
        self.parentIconUrlString = model.parentIconUrl.absoluteString;
        self.parentProjectTitle = model.parentProjectTitle;
        self.parentSiteShortName = model.parentSiteShortName;
        
        self.authorLogin = model.authorLogin;
        self.authorIconUrlString = model.authorIconUrl.absoluteString;
    }
    return self;
}

+ (NSString *)primaryKey {
    return @"postId";
}

- (NSURL *)urlForNewsItem {
    NSString *path;
    if ([self.parentType isEqualToString:@"Project"]) {
        // site baseurl
        path = [NSString stringWithFormat:@"/projects/%ld/journal/%ld",
                (long)self.parentId, (long)self.postId];
    } else {
        path = [NSString stringWithFormat:@"/blog/%ld", (long)self.postId];
    }
    
    if (path) {
        return [[NSURL inat_baseURL] URLByAppendingPathComponent:path];
    } else {
        return nil;
    }
}

- (NSURL *)coverImageUrl {
    return [NSURL URLWithString:self.coverImageUrlString];
}

- (NSURL *)parentIconUrl {
    return [NSURL URLWithString:self.parentIconUrlString];
}

- (NSURL *)authorIconUrl {
    return [NSURL URLWithString:self.authorIconUrlString];
}

@end
