//
//  ExploreCommentCell.m
//  Explore Prototype
//
//  Created by Alex Shepard on 10/12/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>
#import <FontAwesomeKit/FAKIonIcons.h>

#import "ExploreCommentCell.h"
#import "ExploreComment.h"
#import "UIColor+ExploreColors.h"

@interface ExploreCommentCell () {
    ExploreComment *_comment;
    
    UILabel *commentLabel;
    
    UILabel *commenterAndDateLabel;
    UIImageView *commenterImageView;
}
@end

static NSDateFormatter *shortDateFormatter;
static UIImage *userIconPlaceholder;

@implementation ExploreCommentCell

// designated initializer for UITableViewCell
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        if (!shortDateFormatter) {
            shortDateFormatter = [[NSDateFormatter alloc] init];
            shortDateFormatter.dateStyle = NSDateFormatterShortStyle;
            shortDateFormatter.timeStyle = NSDateFormatterNoStyle;
        }
        
        FAKIcon *person = [FAKIonIcons ios7PersonIconWithSize:20.0f];
        [person addAttribute:NSForegroundColorAttributeName value:[UIColor inatBlack]];
        userIconPlaceholder = [person imageWithSize:CGSizeMake(20.0f, 20.0f)];
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        //self.contentView.backgroundColor = [UIColor whiteColor];
        
        commentLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.textColor = [UIColor blackColor];
            label.font = [UIFont systemFontOfSize:12.0f];
            label.numberOfLines = 0;
            
            label;
        });
        [self.contentView addSubview:commentLabel];

        commenterAndDateLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.translatesAutoresizingMaskIntoConstraints = NO;
            
            label.textColor = [UIColor inatGray];
            label.font = [UIFont systemFontOfSize:10.0f];
            label.numberOfLines = 1;
            
            label;
        });
        [self.contentView addSubview:commenterAndDateLabel];

        commenterImageView = ({
            UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectZero];
            iv.translatesAutoresizingMaskIntoConstraints = NO;
            
            iv.contentMode = UIViewContentModeScaleAspectFit;
            iv.layer.cornerRadius = 10.0f;
            iv.clipsToBounds = YES;
            
            iv;
        });
        [self.contentView addSubview:commenterImageView];
        
        UIView *separator = ({
            UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
            view.translatesAutoresizingMaskIntoConstraints = NO;
            
            view.backgroundColor = [[UIColor inatGray] colorWithAlphaComponent:0.2];
            
            view;
        });
        [self.contentView addSubview:separator];
        
        NSDictionary *views = @{
                                @"commentLabel": commentLabel,
                                @"commenterAndDateLabel": commenterAndDateLabel,
                                @"commenterImageView": commenterImageView,
                                @"separator": separator,
                                };
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[commentLabel]-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[commenterAndDateLabel]-[commenterImageView(==20)]-10-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-10-[separator]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        // commenter image view is square (or at least its frame is square)
        [self addConstraint:[NSLayoutConstraint constraintWithItem:commenterImageView
                                                         attribute:NSLayoutAttributeHeight
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:commenterImageView
                                                         attribute:NSLayoutAttributeWidth
                                                        multiplier:1.0f
                                                          constant:0.0f]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-10-[commentLabel]-3-[commenterAndDateLabel]-10-[separator(==1)]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:commenterImageView
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:commenterAndDateLabel
                                                         attribute:NSLayoutAttributeCenterY
                                                        multiplier:1.0f
                                                          constant:0.0f]];

    }
    
    return self;
}


- (ExploreComment *)comment {
    return _comment;
}

- (void)setComment:(ExploreComment *)comment {
    _comment = comment;
    
    if (comment.commenterIconUrl) {
        [commenterImageView sd_setImageWithURL:[NSURL URLWithString:comment.commenterIconUrl]
                              placeholderImage:userIconPlaceholder
                                     completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                         [commenterImageView setNeedsDisplay];
                                     }];
    } else {
        commenterImageView.image = nil;
    }
    
    commentLabel.text = comment.commentText;
    
    NSString *dateString;
    @synchronized(shortDateFormatter) {
        dateString = [shortDateFormatter stringFromDate:comment.commentedDate];
    }
    commenterAndDateLabel.text = [NSString stringWithFormat:@"Added by %@ on %@",
                                  comment.commenterName, dateString];

    
    // configure UI
    
    
}

+(CGFloat)rowHeightForComment:(ExploreComment *)comment withWidth:(CGFloat)width {
    CGSize maxSize = CGSizeMake(width, 999.0f);    // max - perverse
    UIFont *font = [UIFont systemFontOfSize:12.0f];
    
    CGRect textRect = [comment.commentText boundingRectWithSize:maxSize
                                                        options:NSStringDrawingUsesLineFragmentOrigin
                                                     attributes:@{NSFontAttributeName:font}
                                                        context:nil];
    
    return textRect.size.height + 44.0f;    // 10 + 3 + 10 + 20 + 1
}

@end
