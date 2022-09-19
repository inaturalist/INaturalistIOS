//
//  ProjectAboutInfoCell.h
//  iNaturalist
//
//  Created by Alex Shepard on 3/22/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProjectAboutInfoCell : UITableViewCell

@property IBOutlet UILabel *infoTextLabel;

+ (CGFloat)heightForRowWithInfoText:(NSString *)text inTableView:(UITableView *)tableView;
+ (CGFloat)heightForRowWithInfoAttributedText:(NSAttributedString *)attributedText inTableView:(UITableView *)tableView;

@end
