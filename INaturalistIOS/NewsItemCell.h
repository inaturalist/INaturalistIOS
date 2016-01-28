//
//  ProjectPostCell.h
//  iNaturalist
//
//  Created by Alex Shepard on 1/20/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NewsItemCell : UITableViewCell


@property IBOutlet UIImageView *newsCategoryImageView;
@property IBOutlet UILabel *newsCategoryTitle;

@property IBOutlet UILabel *postedAt;
@property IBOutlet UILabel *postBody;
@property IBOutlet UILabel *postTitle;
@property IBOutlet UIImageView *postImageView;

@end
