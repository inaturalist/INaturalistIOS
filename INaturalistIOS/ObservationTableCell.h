//
//  ObservationTableCell.h
//  iNaturalist
//
//  Created by Alex Shepard on 2/19/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ObservationTableCell : UITableViewCell

@property UIImageView *obsImageView;
@property UILabel *title;
@property UILabel *subtitle;
@property UILabel *upperRight;
@property UIImageView *syncImage;
@property UIButton *activityButton;
@property UIButton *interactiveActivityButton;

@end
