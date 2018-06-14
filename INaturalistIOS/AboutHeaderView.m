//
//  AboutHeaderView.m
//  iNaturalist
//
//  Created by Alex Shepard on 6/13/18.
//  Copyright © 2018 iNaturalist. All rights reserved.
//

#import "AboutHeaderView.h"

@implementation AboutHeaderView

+(instancetype)fromXib {
    NSBundle *bundle = [NSBundle mainBundle];
    NSArray *views = [bundle loadNibNamed:@"AboutHeaderView" owner:self options:nil];
    return [views firstObject];
}

@end
