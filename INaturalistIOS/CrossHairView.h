//
//  CrossHairView.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/29/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EditLocationAnnoView.h"

@interface CrossHairView : EditLocationAnnoView
@property (nonatomic, strong) UILabel *xLabel;
@property (nonatomic, strong) UILabel *yLabel;

- (void)initSubviews;
@end
