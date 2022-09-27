//
//  MediaPageControlCell.h
//  iNaturalist
//
//  Created by Alex Shepard on 2/3/21.
//  Copyright © 2021 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MediaPageControlCell : UITableViewCell

@property IBOutlet UIPageControl *pageControl;
@property IBOutlet UIImageView *iv;
@property IBOutlet UIActivityIndicatorView *spinner;
@property IBOutlet UIView *captiveContainer;
@property IBOutlet UIButton *captiveInfoButton;
@property IBOutlet UIButton *shareButton;

@end
