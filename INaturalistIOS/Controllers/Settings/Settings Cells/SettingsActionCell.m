//
//  SettingsActionCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 7/9/18.
//  Copyright © 2018 iNaturalist. All rights reserved.
//

#import "SettingsActionCell.h"
#import "UIColor+INaturalist.h"

@implementation SettingsActionCell

- (void)awakeFromNib {
    [super awakeFromNib];

    self.actionLabel.textColor = [UIColor inatTint];
}

@end
