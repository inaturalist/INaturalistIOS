//
//  ExploreIdentificationCell.h
//  Explore Prototype
//
//  Created by Alex Shepard on 10/12/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ExploreIdentification;

@interface ExploreIdentificationCell : UITableViewCell

@property ExploreIdentification *identification;

+(CGFloat)rowHeightForIdentification:(ExploreIdentification *)identification withWidth:(CGFloat)width;

@end
