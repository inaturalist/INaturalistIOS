//
//  ObservationViewCellError.h
//  iNaturalist
//
//  Created by Alex Shepard on 9/29/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ObservationViewCell.h"

@interface ObservationViewErrorCell : ObservationViewCell

@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *validationErrorLabel;

@end
