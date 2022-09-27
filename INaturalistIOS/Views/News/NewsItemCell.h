//
//  ProjectPostCell.h
//  iNaturalist
//
//  Created by Alex Shepard on 1/20/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NewsItemCell : UITableViewCell


@property UIImageView *newsCategoryImageView;
@property UILabel *newsCategoryTitle;

@property UILabel *postedAt;
@property UILabel *postBody;
@property UILabel *postTitle;
@property UIImageView *postImageView;

- (void)showPostImageView:(BOOL)shouldShow;

@end
