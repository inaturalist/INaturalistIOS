//
//  SettingsDetailTextCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 7/9/18.
//  Copyright © 2018 iNaturalist. All rights reserved.
//

#import "SettingsDetailTextCell.h"

@implementation SettingsDetailTextCell

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.leadingTextLabel.text = nil;
    self.trailingTextLabel.text = nil;
    self.accessoryType = UITableViewCellAccessoryNone;
}

@end
