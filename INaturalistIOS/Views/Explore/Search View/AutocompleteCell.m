//
//  AutocompleteCell.m
//  Explore Prototype
//
//  Created by Alex Shepard on 10/9/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "AutocompleteCell.h"
#import "UIColor+ExploreColors.h"

@interface AutocompleteCell () {
    NSString *_searchText;
}

@end

@implementation AutocompleteCell

// designated initializer for UITableViewCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.textLabel.font = [UIFont systemFontOfSize:14.0f];
    }
    return self;
}

- (NSString *)searchText {
    return _searchText;
}

- (void)setSearchText:(NSString *)searchText {
    _searchText = [searchText copy];

    self.textLabel.text = [NSString stringWithFormat:[self activeSearchBaseString], searchText];
}

- (NSString *)activeSearchBaseString {
    switch (self.predicate) {
        case AutocompletePredicateOrganisms:
            return NSLocalizedString(@"Find organisms named '%@'", nil);
            break;
        case AutocompletePredicatePeople:
            return NSLocalizedString(@"Find people named '%@'", nil);
            break;
        case AutocompletePredicateLocations:
            return NSLocalizedString(@"Find locations named '%@'", nil);
            break;
        case AutocompletePredicateProjects:
            return NSLocalizedString(@"Find projects named '%@'", nil);
        default:
            return @"";
            break;
    }
}

@end
