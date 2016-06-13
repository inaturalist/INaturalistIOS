//
//  ExploreCommentCell.h
//  Explore Prototype
//
//  Created by Alex Shepard on 10/12/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ExploreComment;

@interface ExploreCommentCell : UITableViewCell

@property ExploreComment *comment;

+(CGFloat)rowHeightForComment:(ExploreComment *)comment withWidth:(CGFloat)width;

@end
