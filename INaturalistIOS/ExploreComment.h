//
//  ExploreComment.h
//  Explore Prototype
//
//  Created by Alex Shepard on 10/10/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ExploreComment : NSObject

@property (nonatomic, assign) NSInteger commentId;
@property (nonatomic, copy) NSString *commentText;
@property (nonatomic, copy) NSString *commenterName;
@property (nonatomic, assign) NSInteger commenterId;
@property (nonatomic, copy) NSString *commenterIconUrl;
@property (nonatomic, copy) NSDate *commentedDate;

- (NSDate *)date;

@end
