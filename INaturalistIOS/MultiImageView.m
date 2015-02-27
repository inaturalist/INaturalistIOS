//
//  MultiImageView.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/26/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import "MultiImageView.h"

@interface MultiImageView () {
    NSArray *_images;
    
    UIImageView *one;
    UIImageView *two;
    UIImageView *three;
    UIImageView *four;
}
@end

@implementation MultiImageView

- (void)setImages:(NSArray *)images {
    NSAssert(images.count > 0, @"MultiImageView must display at least one image.");
    NSAssert(images.count < 5, @"MultiImageView can display at most four images.");
    
    _images = images;
    
    [self layoutIfNeeded];
}

- (NSArray *)images {
    return _images;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        one = [[UIImageView alloc] initWithFrame:frame];
        two = [[UIImageView alloc] initWithFrame:frame];
        three = [[UIImageView alloc] initWithFrame:frame];
        four = [[UIImageView alloc] initWithFrame:frame];
        
        [@[one,two,three,four] enumerateObjectsUsingBlock:^(UIImageView *iv, NSUInteger idx, BOOL *stop) {
            iv.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
            iv.hidden = YES;
            iv.contentMode = UIViewContentModeScaleAspectFill;
            iv.clipsToBounds = YES;
            
            iv.layer.borderColor = [UIColor grayColor].CGColor;
            iv.layer.borderWidth = 1.0f;
            
            [self addSubview:iv];
        }];
        
    }
    
    return self;
}

- (void)layoutSubviews {
    
    if (self.images.count == 1) {
        one.hidden = NO;
        two.hidden = three.hidden = four.hidden = YES;
        
        one.frame = self.bounds;
        one.image = self.images[0];
        
    } else if (self.images.count == 2) {
        one.hidden = two.hidden = NO;
        three.hidden = four.hidden = YES;
        
        one.frame = CGRectMake(self.frame.origin.x, self.bounds.origin.y,
                               self.bounds.size.width, self.bounds.size.height / 2);
        one.image = self.images[0];
        
        two.frame = CGRectMake(self.frame.origin.x, self.bounds.size.height / 2,
                               self.bounds.size.width, self.bounds.size.height / 2);
        two.image = self.images[1];
        
    } else if (self.images.count == 3) {
        one.hidden = two.hidden = three.hidden = NO;
        four.hidden = YES;
        
        one.frame = CGRectMake(self.bounds.origin.x, self.bounds.origin.y,
                               self.bounds.size.width, self.bounds.size.height / 2);
        one.image = self.images[0];
        
        two.frame = CGRectMake(self.bounds.origin.x, self.bounds.size.height / 2,
                               self.bounds.size.width / 2, self.bounds.size.height / 2);
        two.image = self.images[1];
        
        three.frame = CGRectMake(self.bounds.size.width / 2, self.bounds.size.height / 2,
                                 self.bounds.size.width / 2, self.bounds.size.height / 2);
        three.image = self.images[2];

    } else if (self.images.count == 4) {
        one.hidden = two.hidden = three.hidden = four.hidden = NO;
        
        one.frame = CGRectMake(self.bounds.origin.x, self.bounds.origin.y,
                               self.bounds.size.width / 2, self.bounds.size.height / 2);
        one.image = self.images[0];
        
        two.frame = CGRectMake(self.bounds.size.width / 2, self.bounds.origin.y,
                               self.bounds.size.width / 2, self.bounds.size.height / 2);
        two.image = self.images[1];
        
        three.frame = CGRectMake(self.bounds.origin.x, self.bounds.size.height / 2,
                               self.bounds.size.width / 2, self.bounds.size.height / 2);
        three.image = self.images[2];
        
        four.frame = CGRectMake(self.bounds.size.width / 2, self.bounds.size.height / 2,
                                 self.bounds.size.width / 2, self.bounds.size.height / 2);
        four.image = self.images[3];
    }
    
    [super layoutSubviews];
}

@end
