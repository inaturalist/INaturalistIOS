//
//  AutocompleteCell.h
//  Explore Prototype
//
//  Created by Alex Shepard on 10/9/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "AutocompleteSearchItem.h"

@interface AutocompleteCell : UITableViewCell

@property AutocompletePredicate predicate;
@property NSString *searchText;

@end
