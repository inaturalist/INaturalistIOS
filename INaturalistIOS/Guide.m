//
//  Guide.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 9/1/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import "Guide.h"
#import "NSURL+INaturalist.h"

@implementation Guide

@dynamic title;
@dynamic desc;
@dynamic createdAt;
@dynamic updatedAt;
@dynamic iconURL;
@dynamic localCreatedAt;
@dynamic localUpdatedAt;
@dynamic syncedAt;
@dynamic ngzDownloadedAt;
@dynamic recordID;
@dynamic taxonID;
@dynamic latitude;
@dynamic longitude;
@dynamic taxon;

- (NSString *)dirPath
{
    NSArray *docDirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [docDirs objectAtIndex:0];
    NSString *guidesDirPath = [docDir stringByAppendingPathComponent:@"guides"];
    return [guidesDirPath stringByAppendingPathComponent:self.recordID.stringValue];
}

- (NSString *)xmlPath
{
    return [self.dirPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.xml", self.recordID]];
}

- (NSString *)xmlURL
{
    return [[NSURL URLWithString:[NSString stringWithFormat:@"/guides/%@.xml", self.recordID]
                   relativeToURL:[NSURL inat_baseURL]] absoluteString];
}

// TODO when guide deleted, remove associated data
@end
