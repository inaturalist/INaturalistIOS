//
//  DisclosureCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 9/4/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <AFNetworking/UIImageView+AFNetworking.h>
#import <UIColor-HTMLColors/UIColor+HTMLColors.h>

#import "DisclosureCell.h"

@implementation DisclosureCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.cellImageView = ({
            UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectZero];
            iv.translatesAutoresizingMaskIntoConstraints = NO;
            
            iv.contentMode = UIViewContentModeScaleAspectFill;
            iv.clipsToBounds = YES;
            
            iv;
        });
        [self.contentView addSubview:self.cellImageView];
        
        self.titleLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.numberOfLines = 0;
            
            label;
        });
        [self.contentView addSubview:self.titleLabel];
        
        self.secondaryLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.textColor = [UIColor colorWithHexString:@"#8e8e9e"];
            
            label;
        });
        [self.contentView addSubview:self.secondaryLabel];
        
        [self setNeedsUpdateConstraints];
        
        NSDictionary *views = @{
                                @"iv": self.cellImageView,
                                @"title": self.titleLabel,
                                @"secondary": self.secondaryLabel,
                                };
        
        self.cellConstraints = [NSMutableArray array];
        
        [self.cellConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-7.5-[iv(==29)]"
                                                                                          options:0
                                                                                          metrics:0
                                                                                            views:views]];
        
        [self.cellConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[title]-0-|"
                                                                                          options:0
                                                                                          metrics:0
                                                                                            views:views]];
        [self.cellConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[secondary]-0-|"
                                                                                          options:0
                                                                                          metrics:0
                                                                                            views:views]];
        
        [self.cellConstraints addObjectsFromArray:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-15-[iv]-15-[title]-[secondary]-|"
                                                                                          options:0
                                                                                          metrics:0
                                                                                            views:views]];
        
        [self.cellConstraints addObject:[NSLayoutConstraint constraintWithItem:self.cellImageView
                                                                     attribute:NSLayoutAttributeWidth
                                                                     relatedBy:NSLayoutRelationEqual
                                                                        toItem:self.cellImageView
                                                                     attribute:NSLayoutAttributeHeight
                                                                    multiplier:1.0f
                                                                      constant:0.0f]];

    }
    
    return self;
}

- (void)updateConstraints {
    // TODO: this is slow and unwieldy
    
    if (self.cellConstraints && self.cellConstraints.count > 0) {
        [self removeConstraints:self.cellConstraints];
    }
    [self addConstraints:self.cellConstraints];
    
    [super updateConstraints];
}

- (void)prepareForReuse {
    [self.cellImageView cancelImageRequestOperation];
    self.cellImageView.layer.borderWidth = 0.0f;
    self.cellImageView.layer.borderColor = nil;
    self.cellImageView.layer.cornerRadius = 0.0f;
    
    self.titleLabel.text = nil;
    self.secondaryLabel.text = nil;
    
    self.accessoryType = UITableViewCellAccessoryNone;
    self.accessoryView = nil;
}

+ (CGFloat)heightForRowWithTitle:(NSString *)title inTableView:(UITableView *)tableView {
    // 59 for cell image view to the left, 80 for the potential accessory view to the right
    CGFloat usableWidth = tableView.bounds.size.width - 59 - 80;
    CGSize maxSize = CGSizeMake(usableWidth, CGFLOAT_MAX);
    UIFont *font = [UIFont systemFontOfSize:17.0f];
    
    CGRect textRect = [title boundingRectWithSize:maxSize
                                          options:NSStringDrawingUsesLineFragmentOrigin
                                       attributes:@{ NSFontAttributeName: font }
                                          context:nil];
    
    return MAX(44, textRect.size.height + 14); // 14 for padding
}


@end
