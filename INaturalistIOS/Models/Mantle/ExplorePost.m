//
//  ExplorePost.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/4/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

#import <NSString_stripHtml/NSString_stripHTML.h>

#import "ExplorePost.h"
#import "NSURL+INaturalist.h"

@implementation ExplorePost

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"uuid": @"uuid",
        @"postId": @"id",
        @"postPublishedAt": @"published_at",
        @"postTitle": @"title",
        @"postBody": @"body",
        
        @"parentId": @"parent.id",
        @"parentSiteName": @"parent.name",
        @"parentProjectTitle": @"parent.title",
        @"parentIconUrl": @"parent.icon_url",
        @"parentType": @"parent_type",
        
        @"authorLogin": @"user.login",
        @"authorIconUrl": @"user.user_icon_url",
    };
}

+ (NSValueTransformer *)parentTypeJSONTransformer {
    NSDictionary *parentTypeMappings = @{
        @"Project": @(PostParentTypeProject),
        @"Site": @(PostParentTypeSite),
    };
    
    return [NSValueTransformer mtl_valueMappingTransformerWithDictionary:parentTypeMappings];
}

+ (NSValueTransformer *)parentIconUrlJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

+ (NSValueTransformer *)authorIconUrlJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

+ (NSValueTransformer *)postPublishedAtJSONTransformer {
    static NSDateFormatter *_dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        _dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZ";
    });

    return [MTLValueTransformer transformerWithBlock:^id(id dateString) {
        return [_dateFormatter dateFromString:dateString];
    }];
}

- (NSString *)parentTitleText {
    switch (self.parentType) {
        case PostParentTypeProject:
            return self.parentProjectTitle;
            break;
        case PostParentTypeSite:
            return [NSString stringWithFormat:NSLocalizedString(@"%@ News", @"site news"), self.parentSiteName];
            break;
        default:
            return @"";
            break;
    }
}

- (void)computeProperties {
    NSString *strippedBody = [self.postBody stringByStrippingHTML];
    self.postPlainTextExcerpt = [strippedBody stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
    // this is also a good time to see if there's an embedded image
    NSString *urlString = nil;
    NSString *htmlString = self.postBody;
    NSScanner *theScanner = [NSScanner scannerWithString:htmlString];
    // find start of IMG tag
    [theScanner scanUpToString:@"<img" intoString:nil];
    if (![theScanner isAtEnd]) {
        [theScanner scanUpToString:@"src" intoString:nil];
        NSCharacterSet *charset = [NSCharacterSet characterSetWithCharactersInString:@"\"'"];
        [theScanner scanUpToCharactersFromSet:charset intoString:nil];
        [theScanner scanCharactersFromSet:charset intoString:nil];
        [theScanner scanUpToCharactersFromSet:charset intoString:&urlString];
        NSURL *imageURL = [NSURL URLWithString:urlString];
        if (imageURL) {
            self.postCoverImageUrl = imageURL;
        }
    }
}

- (NSURL *)urlForNewsItem {
    NSString *path;
    switch (self.parentType) {
        case PostParentTypeProject:
            path = [NSString stringWithFormat:@"/projects/%ld/journal/%ld",
                    (long)self.parentId,
                    (long)self.postId];
            break;
        case PostParentTypeSite:
            path = [NSString stringWithFormat:@"/blog/%ld",
                    (long)self.postId];
            break;
        default:
            path = nil;
            break;
    }
        
    if (path) {
        return [[NSURL inat_baseURL] URLByAppendingPathComponent:path];
    } else {
        return nil;
    }
}

- (BOOL)isEqualToExplorePost:(ExplorePost *)other {
    // this is the server primary key for posts
    return [self.uuid isEqualToString:other.uuid];
}

- (BOOL)isEqual:(id)other {
    if (self == other) {
        return YES;
    }
    
    if (![other isKindOfClass:[ExplorePost class]]) {
        return NO;
    }

    return [self isEqualToExplorePost:(ExplorePost *)other];
}

- (NSUInteger)hash {
    return [[self uuid] hash];
}

@end
