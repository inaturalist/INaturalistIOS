//
//  IconAndTextControl.h
//  iNaturalist
//
//  Created by Alex Shepard on 8/28/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface IconAndTextControl : UIControl

@property NSAttributedString *attributedIconTitle;
@property NSString *textTitle;
@property UIColor *textColor;
@property UIColor *separatorColor;

@end
