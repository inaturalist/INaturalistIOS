//
//  ProjectTableViewCell.h
//  iNaturalist
//
//  Created by Eldad Ohana on 7/13/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProjectTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *projectImage;

@end
