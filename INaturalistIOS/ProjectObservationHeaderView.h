//
//  ProjectObservationHeaderView.h
//  iNaturalist
//
//  Created by Alex Shepard on 10/7/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProjectObservationHeaderView : UIView

@property IBOutlet UIImageView *projectThumbnailImageView;
@property IBOutlet UILabel *projectTitleLabel;
@property IBOutlet UILabel *projectTypeLabel;
@property IBOutlet UISwitch *selectedSwitch;

@end
