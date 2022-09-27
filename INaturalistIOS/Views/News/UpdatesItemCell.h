//
//  UpdatesItemCell.h
//  iNaturalist
//
//  Created by Alex Shepard on 10/21/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UpdatesItemCell : UITableViewCell
@property IBOutlet UIImageView *profileImageView;
@property IBOutlet UIImageView *observationImageView;
@property IBOutlet UILabel *updateTextLabel;
@property IBOutlet UILabel *updateDateTextLabel;
@end
