//
//  ExploreComment.h
//  Explore Prototype
//
//  Created by Alex Shepard on 10/10/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

#import "CommentVisualization.h"
#import "ActivityVisualization.h"

@class ExploreUser;

@interface ExploreComment : MTLModel <CommentVisualization, MTLJSONSerializing>

@property (nonatomic, assign) NSInteger commentId;
@property (nonatomic, copy) NSString *commentText;
@property (nonatomic, retain) ExploreUser *commenter;
@property (nonatomic, copy) NSDate *commentedDate;

@end
