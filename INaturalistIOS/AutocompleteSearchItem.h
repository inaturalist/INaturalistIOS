//
//  AutocompleteSearchItem.h
//  iNaturalist
//
//  Created by Alex Shepard on 11/12/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, AutocompletePredicate) {
    AutocompletePredicateOrganisms,
    AutocompletePredicatePeople,
    AutocompletePredicateLocations,
    AutocompletePredicateProjects
};

typedef void (^SearchAction)(NSString *searchText);

@interface AutocompleteSearchItem : NSObject

// shortcut items have user input text attached
// ie search taxa ("snakes") or search people ("alex")
@property AutocompletePredicate predicate;
@property (nonatomic, copy) SearchAction action;;

+ (instancetype)itemWithPredicate:(AutocompletePredicate)predicate action:(SearchAction)action;

@end
