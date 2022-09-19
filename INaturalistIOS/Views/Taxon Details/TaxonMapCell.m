//
//  TaxonMapCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 5/23/17.
//  Copyright © 2017 iNaturalist. All rights reserved.
//

#import <FontAwesomeKit/FAKIonIcons.h>

#import "TaxonMapCell.h"

@implementation TaxonMapCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    FAKIcon *alert = [FAKIonIcons alertCircledIconWithSize:40];
    self.noNetworkAlertIcon.attributedText = [alert attributedString];
    
    self.noNetworkLabel.text = NSLocalizedString(@"No network connection.", nil);
    self.noObservationsLabel.text = NSLocalizedString(@"No observations yet.", nil);
    
}

@end
