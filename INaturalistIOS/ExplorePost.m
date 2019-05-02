//
//  ExplorePost.m
//  iNaturalist
//
//  Created by Alex Shepard on 10/29/18.
//  Copyright © 2018 iNaturalist. All rights reserved.
//

#import "ExplorePost.h"
#import "NSURL+INaturalist.h"

@implementation ExplorePost

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError **)error {
    self = [super initWithDictionary:dictionaryValue error:error];
    if (self == nil) return nil;
    
    // compute additional properties
    if (!self.excerpt) {
        NSString *strippedBody = [self.body stringByStrippingHTML];
        self.excerpt = [strippedBody stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        
        // this is also a good time to see if there's an embedded image
        NSString *urlString = nil;
        NSString *htmlString = self.body;
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
                self.coverImageUrl = imageURL;
            }
        }
    }

    return self;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
             @"postId": @"id",
             @"publishedAt": @"published_at",
             @"body": @"body",
             @"title": @"title",
             @"coverImageUrl": @"cover_image_url",
             
             @"parentType": @"parent_type",
             @"parentIconUrl": @"parent.icon_url",
             @"parentProjectTitle": @"parent.title",
             @"parentId": @"parent_id",
             @"parentSiteShortName": @"parent.site_name_short",
             
             @"authorLogin": @"user.login",
             @"authorIconUrl": @"user.user_icon_url",
             };
}

+ (NSValueTransformer *)authorIconUrlJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

+ (NSValueTransformer *)coverImageUrlJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

+ (NSValueTransformer *)parentIconUrlJSONTransformer {
    return [NSValueTransformer valueTransformerForName:MTLURLValueTransformerName];
}

+ (NSValueTransformer *)publishedAtJSONTransformer {
    static NSDateFormatter *_dateFormatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _dateFormatter = [[NSDateFormatter alloc] init];
        _dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        // uses rails-style date formatting
        // TODO: this isn't working
        _dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZ";
    });
    
    return [MTLValueTransformer transformerWithBlock:^id(id dateString) {
        return [_dateFormatter dateFromString:dateString];
    }];
}

- (NSURL *)urlForNewsItem {
    NSString *path;
    if ([self.parentType isEqualToString:@"Project"]) {
        // site baseurl
        path = [NSString stringWithFormat:@"/projects/%ld/journal/%ld",
                (long)self.parentId, (long)self.postId];
    } else {
        path = [NSString stringWithFormat:@"/blog/%ld",
                (long)self.postId];
    }
    
    if (path) {
        return [[NSURL inat_baseURL] URLByAppendingPathComponent:path];
    } else {
        return nil;
    }
}

@end
