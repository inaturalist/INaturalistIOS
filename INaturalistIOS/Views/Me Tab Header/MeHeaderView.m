//
//  MeHeaderView.m
//  iNaturalist
//
//  Created by Alex Shepard on 3/11/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import "MeHeaderView.h"
#import "UIColor+INaturalist.h"
#import <FontAwesomeKit/FAKIonIcons.h>

@interface MeHeaderView ()
@property BOOL isAnimating;
@end

@implementation MeHeaderView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.backgroundColor = [UIColor inatDarkGray];
    
    self.iconButton.layer.borderWidth = 2.0f;
    self.iconButton.layer.borderColor = UIColor.whiteColor.CGColor;
    // circular with an 80x80 frame
    self.iconButton.layer.cornerRadius = 40.0f;
    self.iconButton.clipsToBounds = YES;
    
    self.uploadingSpinner.hidden = YES;
    self.uploadingSpinner.color = UIColor.whiteColor;
    
    self.obsCountLabel.font = [UIFont systemFontOfSize:18.0f];
    self.obsCountLabel.textColor = [UIColor whiteColor];
    self.obsCountLabel.textAlignment = NSTextAlignmentNatural;    
}

- (void)startAnimatingUpload {
    self.uploadingSpinner.hidden = NO;
    [self.uploadingSpinner startAnimating];
    [self setNeedsDisplay];
}

- (void)stopAnimatingUpload {
    self.uploadingSpinner.hidden = YES;
    [self.uploadingSpinner stopAnimating];
    [self setNeedsDisplay];
}


@end
