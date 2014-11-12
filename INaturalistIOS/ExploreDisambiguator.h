//
//  ExploreDisambiguator.h
//  iNaturalist
//
//  Created by Alex Shepard on 11/11/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^DismbiguationChosen)(id choice);

@interface ExploreDisambiguator : NSObject <UITableViewDataSource,UITableViewDelegate>

@property NSString *title;
@property NSString *message;

@property NSArray *searchOptions;
@property (nonatomic, copy) DismbiguationChosen chosenBlock;

- (void)presentDisambiguationAlert;

@end
