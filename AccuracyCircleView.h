//
//  AccuracyCircleView.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/1/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EditLocationAnnoView.h"

@interface AccuracyCircleView : EditLocationAnnoView
@property (nonatomic, assign) float radius;
@property (nonatomic, strong) UILabel *label;
@end
