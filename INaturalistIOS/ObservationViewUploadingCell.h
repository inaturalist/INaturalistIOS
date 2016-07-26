//
//  ObservationViewCellUploading.h
//  iNaturalist
//
//  Created by Alex Shepard on 9/29/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <YLProgressBar/YLProgressBar.h>
#import "ObservationViewCell.h"

@interface ObservationViewUploadingCell : ObservationViewCell

@property IBOutlet YLProgressBar *progressBar;
@property IBOutlet UILabel *dateLabel;

@end
