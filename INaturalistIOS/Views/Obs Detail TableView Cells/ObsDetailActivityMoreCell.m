//
//  ObsDetailActivityMoreCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/21/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import "ObsDetailActivityMoreCell.h"
#import "UIColor+INaturalist.h"

@implementation ObsDetailActivityMoreCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self.agreeButton setTitleColor:[UIColor inatTint]
                           forState:UIControlStateNormal];
    [self.agreeButton setTitleColor:[UIColor lightGrayColor]
                           forState:UIControlStateDisabled];
    
    NSString *agreeText = NSLocalizedString(@"Agree", @"Label for a button that adds an ID of the same taxon as the current one, so the sense is 'I agree with this identification'");
    [self.agreeButton setTitle:agreeText
                      forState:UIControlStateNormal];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    [self.agreeButton removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];
}

@end
