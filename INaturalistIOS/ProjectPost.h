//
//  ProjectPost.h
//  iNaturalist
//
//  Created by Alex Shepard on 1/14/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "INatModel.h"

@class User;

@interface ProjectPost : INatModel

@property (nonatomic, retain) NSNumber *recordID;
@property (nonatomic, retain) NSDate *publishedAt;
@property (nonatomic, retain) NSString *body;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSDate * syncedAt;
@property (nonatomic, retain) NSNumber *projectID;
@property (nonatomic, retain) NSString *projectTitle;
@property (nonatomic, retain) NSString *projectIconUrl;

// relationships
@property (nonatomic, retain) User *author;

@end
