//
//  ObservationViewCell.h
//  iNaturalist
//
//  Created by Eldad Ohana on 7/2/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

static const int ObservationCellImageTag = 5;
static const int ObservationCellTitleTag = 1;
static const int ObservationCellSubTitleTag = 2;
static const int ObservationCellUpperRightTag = 3;
static const int ObservationCellLowerRightTag = 4;
static const int ObservationCellActivityButtonTag = 6;
static const int ObservationCellActivityInteractiveButtonTag = 7;

@interface ObservationViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *observationImage;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UIButton *interactiveActivityButton;
@property (weak, nonatomic) IBOutlet UIButton *activityButton;
@property (weak, nonatomic) IBOutlet UIImageView *syncImage;
@property IBOutlet UIButton *uploadButton;
@property IBOutlet UIProgressView *uploadProgress;


@end
