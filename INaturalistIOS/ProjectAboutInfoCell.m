//
//  ProjectAboutInfoCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 3/22/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "ProjectAboutInfoCell.h"

@implementation ProjectAboutInfoCell

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

+ (CGFloat)heightForRowWithInfoText:(NSString *)text inTableView:(UITableView *)tableView {
    // 20 for the margins on the left and right
    CGFloat usableWidth = tableView.bounds.size.width - 20 - 20;
    CGSize maxSize = CGSizeMake(usableWidth, CGFLOAT_MAX);
    UIFont *font = [UIFont systemFontOfSize:14.0f];
    
    CGRect textRect = [text boundingRectWithSize:maxSize
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:@{ NSFontAttributeName: font }
                                         context:nil];
    
    // 32 for padding... 16 seemed to be truncating some longer text
    return MAX(44, textRect.size.height + 32);
}

+ (CGFloat)heightForRowWithInfoAttributedText:(NSAttributedString *)attributedText inTableView:(UITableView *)tableView {
    // 20 for the margins on the left and right
    CGFloat usableWidth = tableView.bounds.size.width - 20 - 20;
    CGSize maxSize = CGSizeMake(usableWidth, CGFLOAT_MAX);
    
    CGRect textRect = [attributedText boundingRectWithSize:maxSize
                                                   options:NSStringDrawingUsesLineFragmentOrigin
                                                   context:nil];

    // 32 for padding... 16 seemed to be truncating some longer text
    return MAX(44, textRect.size.height + 32);
}


@end
