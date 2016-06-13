//
//  AutocompleteCell.m
//  Explore Prototype
//
//  Created by Alex Shepard on 10/9/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <FontAwesomeKit/FAKIonIcons.h>

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
    
    // use an attributed string to make the text vary
    NSString *str = [NSString stringWithFormat:NSLocalizedString(@"Find %@ named '", nil), self.predicate];     // un-localizable in this format
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:str];
    [attr addAttributes:@{ NSFontAttributeName: [UIFont boldSystemFontOfSize:14.0f] }
                  range:[str rangeOfString:self.predicate]];
    
    NSAttributedString *attr2 = [[NSAttributedString alloc] initWithString:searchText
                                                                attributes:@{ NSFontAttributeName: [UIFont italicSystemFontOfSize:14.0f] }];
    [attr appendAttributedString:attr2];
    
    NSAttributedString *attr3 = [[NSAttributedString alloc] initWithString:@"'" attributes:@{}];
    [attr appendAttributedString:attr3];
    
    self.textLabel.attributedText = attr;
}

@end
