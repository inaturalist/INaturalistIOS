//
//  ObservationViewCell.h
//  iNaturalist
//
//  Created by Alex Shepard on 9/29/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ObservationViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *observationImage;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;

@end
