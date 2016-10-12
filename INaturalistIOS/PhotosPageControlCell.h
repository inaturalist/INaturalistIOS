//
//  PhotosPageControlCell.h
//  iNaturalist
//
//  Created by Alex Shepard on 11/18/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PhotosPageControlCell : UITableViewCell

@property IBOutlet UIPageControl *pageControl;
@property IBOutlet UIImageView *iv;
@property IBOutlet UIActivityIndicatorView *spinner;
@property IBOutlet UIView *captiveContainer;
@property IBOutlet UIButton *captiveInfoButton;
@property IBOutlet UIButton *shareButton;

@end
