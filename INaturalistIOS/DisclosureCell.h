//
//  DisclosureCell.h
//  iNaturalist
//
//  Created by Alex Shepard on 9/4/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DisclosureCell : UITableViewCell
@property UIImageView *cellImageView;
@property UILabel *titleLabel;
@property UILabel *secondaryLabel;      // to the right of the title
@property NSMutableArray *cellConstraints;
+ (CGFloat)heightForRowWithTitle:(NSString *)title inTableView:(UITableView *)tableView;
@end
