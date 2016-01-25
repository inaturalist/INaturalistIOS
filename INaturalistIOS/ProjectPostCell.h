//
//  ProjectPostCell.h
//  iNaturalist
//
//  Created by Alex Shepard on 1/20/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProjectPostCell : UITableViewCell

@property IBOutlet UIImageView *projectImageView;
@property IBOutlet UILabel *projectName;
@property IBOutlet UILabel *postedAt;
@property IBOutlet UILabel *postBody;
@property IBOutlet UIImageView *postImageView;

@end
