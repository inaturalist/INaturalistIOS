//
//  PhotoScrollView.m
//  iNaturalist
//
//  Created by Alex Shepard on 9/9/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <FontAwesomeKit/FAKIonIcons.h>

#import "PhotoScrollView.h"
#import "ObservationPhoto.h"
#import "ImageStore.h"

@interface PhotoScrollView () {
    NSArray *_photos;
}
@property UIScrollView *scrollView;

@end

@implementation PhotoScrollView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.scrollView = [[UIScrollView alloc] initWithFrame:frame];
        self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        
        [self addSubview:self.scrollView];
    }
    
    return self;
}

#pragma mark - ScrollView configuration

- (void)configureScrollView {
    self.scrollView.frame = self.bounds;
    
    NSInteger numCells = self.photos.count + 1;

    // each photo 90 px wide?
    CGFloat width = numCells * (71 + 18) + 9;
    CGFloat height = self.bounds.size.height;
    self.scrollView.contentSize = CGSizeMake(width, height);
    
    NSArray *subviews = self.scrollView.subviews;
    for (UIView *view in subviews) {
        [view removeFromSuperview];
    }
    
    // 100 - 20 = 80
    // 80 - 20 = 60
    
    // add new photo button
    self.addButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.addButton.accessibilityLabel = @"Add Button";
    self.addButton.frame = CGRectMake(9, 12, 71, 71);
    self.addButton.layer.borderColor = [UIColor grayColor].CGColor;
    self.addButton.layer.borderWidth = 1.0f;
    self.addButton.tintColor = [UIColor grayColor];
    [self.addButton addTarget:self action:@selector(addPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    FAKIcon *plus = [FAKIonIcons iosPlusEmptyIconWithSize:25];
    [self.addButton setAttributedTitle:plus.attributedString forState:UIControlStateNormal];
    
    [self.scrollView addSubview:self.addButton];
    
    static NSAttributedString *defaultPhotoStr, *nonDefaultPhotoStr;
    if (!defaultPhotoStr) {
        FAKIcon *check = [FAKIonIcons iosCheckmarkOutlineIconWithSize:13];
        NSMutableAttributedString *defaultPhotoMutable = [[NSMutableAttributedString alloc] initWithAttributedString:check.attributedString];
        [defaultPhotoMutable appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];
        [defaultPhotoMutable appendAttributedString:[[NSAttributedString alloc] initWithString:@"Default"
                                                                                    attributes:@{
                                                                                                 NSFontAttributeName: [UIFont systemFontOfSize:12],
                                                                                                 }]];
        defaultPhotoStr = [[NSAttributedString alloc] initWithAttributedString:defaultPhotoMutable];
    }
    if (!nonDefaultPhotoStr) {
        FAKIcon *circle = [FAKIonIcons iosCircleOutlineIconWithSize:13];
        nonDefaultPhotoStr = [circle attributedString];
    }

    for (int i = 1; i < numCells; i++) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(i * (71 + 18), 0, 71 + 18, self.bounds.size.height)];
        view.tag = 100 + i - 1;
        
        view.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(9, 12, 71, 71)];
        iv.contentMode = UIViewContentModeScaleAspectFill;
        iv.clipsToBounds = YES;
        ObservationPhoto *obsPhoto = (ObservationPhoto *)self.photos[i-1];
        iv.image = [[ImageStore sharedImageStore] find:obsPhoto.photoKey forSize:ImageStoreSmallSize];
        [view addSubview:iv];
        
        [self.scrollView addSubview:view];
        
        UIButton *delete = [UIButton buttonWithType:UIButtonTypeSystem];
        delete.tag = i-1;
        [delete addTarget:self action:@selector(deletePressed:) forControlEvents:UIControlEventTouchUpInside];
        delete.frame = CGRectMake(0, 0, 22, 22);
        delete.center = CGPointMake(iv.frame.origin.x + iv.bounds.size.width, iv.frame.origin.y + 4);
        delete.layer.cornerRadius = 11;
        FAKIcon *close = [FAKIonIcons closeIconWithSize:10];
        [delete setAttributedTitle:close.attributedString forState:UIControlStateNormal];
        delete.tintColor = [UIColor whiteColor];
        delete.backgroundColor = [UIColor grayColor];
        [view addSubview:delete];
        
        if (i == 1) {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(9, 12 + 71, 71 + 18, 21)];
            label.attributedText = defaultPhotoStr;
            label.textColor = [UIColor grayColor];
            [view addSubview:label];
        } else {
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            
            // tweak the baseline of the empty circle
            button.contentEdgeInsets = UIEdgeInsetsMake(0, 0, -2, 0);
            
            button.frame = CGRectMake(9, 12 + 71, 71 + 18, 21);
            [button setAttributedTitle:nonDefaultPhotoStr forState:UIControlStateNormal];
            button.tintColor = [UIColor grayColor];
            button.titleLabel.textColor = [UIColor grayColor];
            button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
            button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
            button.tag = i-1;
            [button addTarget:self action:@selector(setDefault:) forControlEvents:UIControlEventTouchUpInside];
            [view addSubview:button];
        }
    }
}

#pragma mark - UIButton targets
- (void)deletePressed:(UIButton *)button {
    if (self.delegate && [self.delegate respondsToSelector:@selector(photoScrollView:deletedIndex:)]) {
        [self.delegate photoScrollView:self deletedIndex:button.tag];
    }
}

- (void)addPressed:(UIButton *)button {
    if (self.delegate && [self.delegate respondsToSelector:@selector(photoScrollViewAddPressed:)]) {
        [self.delegate photoScrollViewAddPressed:self];
    }
}

- (void)setDefault:(UIButton *)button {
    // swap the two
    UIView *originalDefault = [self.scrollView viewWithTag:100 + 0];
    CGPoint originalDefaultCenter = originalDefault.center;
    UIView *newDefault = [self.scrollView viewWithTag:100 + button.tag];
    CGPoint newDefaultCenter = newDefault.center;
    
    // bring the original & new to the top
    // new at the top, original right below
    [self.scrollView bringSubviewToFront:originalDefault];
    [self.scrollView bringSubviewToFront:newDefault];
    
    for (UIView *view in originalDefault.subviews) {
        if ([view isKindOfClass:[UIButton class]]) {
            view.hidden = YES;
        }
        if ([view isKindOfClass:[UILabel class]]) {
            view.hidden = YES;
        }

    }
    for (UIView *view in newDefault.subviews) {
        if ([view isKindOfClass:[UIButton class]]) {
            view.hidden = YES;
        }
    }
    
    
    [UIView animateWithDuration:0.1f
                     animations:^{
                         newDefault.transform = CGAffineTransformMakeScale(1.1, 1.1);
                         originalDefault.transform = CGAffineTransformMakeScale(0.9, 0.9);

                     } completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.33f
                                          animations:^{
                                              [self.scrollView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];

                                              // swap the two
                                              originalDefault.center = newDefaultCenter;
                                              newDefault.center = originalDefaultCenter;
                                          } completion:^(BOOL finished) {
                                              [UIView animateWithDuration:0.1f
                                                               animations:^{
                                                                   newDefault.transform = CGAffineTransformIdentity;
                                                                   originalDefault.transform = CGAffineTransformIdentity;
                                                               } completion:^(BOOL finished) {
                                                                   if (self.delegate && [self.delegate respondsToSelector:@selector(photoScrollView:setDefaultIndex:)]) {
                                                                       [self.delegate photoScrollView:self setDefaultIndex:button.tag];
                                                                   }
                                                               }];
                                          }];
                     }];
    
    

}


#pragma mark - Setter/Getter

- (void)setPhotos:(NSArray *)photos {
    _photos = photos;
    
    [self configureScrollView];
}

- (NSArray *)photos {
    return _photos;
}

@end
