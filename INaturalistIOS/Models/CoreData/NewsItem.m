//
//  NewsItem.m
//  iNaturalist
//
//  Created by Alex Shepard on 1/27/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

@import NSString_stripHtml;

#import "NewsItem.h"
#import "NSURL+INaturalist.h"

@implementation NewsItem

@dynamic parentIconUrl;
@dynamic parentProjectTitle;
@dynamic parentRecordID;
@dynamic parentSiteShortName;
@dynamic parentTypeString;

@dynamic postBody;
@dynamic postPublishedAt;
@dynamic postTitle;
@dynamic postPlainTextExcerpt;
@dynamic postCoverImageUrl;

@dynamic authorLogin;
@dynamic authorIconUrl;

@dynamic recordID;
@dynamic syncedAt;
@dynamic localUpdatedAt;

- (NSString *)parentTitleText {
    if ([self.parentTypeString isEqualToString:@"Site"]) {
        return [NSString stringWithFormat:NSLocalizedString(@"%@ News", @"site news"), self.parentSiteShortName];
    } else if ([self.parentTypeString isEqualToString:@"Project"]) {
        return self.parentProjectTitle;
    } else {
        return @"";
    }
}

- (void)awakeFromFetch {
    [super awakeFromFetch];
    
    if (!self.postPlainTextExcerpt) {
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
                self.postCoverImageUrl = urlString;
            }
        }
    }
}

- (NSURL *)urlForNewsItem {
    NSString *path;
    if ([self.parentTypeString isEqualToString:@"Project"]) {
        // site baseurl
        path = [NSString stringWithFormat:@"/projects/%ld/journal/%ld",
                (long)self.parentRecordID.integerValue,
                (long)self.recordID.integerValue];
    } else {
        path = [NSString stringWithFormat:@"/blog/%ld",
                (long)self.recordID.integerValue];
    }

    if (path) {
        return [[NSURL inat_baseURL] URLByAppendingPathComponent:path];
    } else {
        return nil;
    }
}

@end
