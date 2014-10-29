//
//  ExploreSearchCompleteCell.h
//  Explore Prototype
//
//  Created by Alex Shepard on 10/9/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ExploreSearchPredicate.h"

@interface ExploreSearchCompleteCell : UITableViewCell

@property ExploreSearchPredicateType searchPredicateType;
@property NSString *searchText;

@end
