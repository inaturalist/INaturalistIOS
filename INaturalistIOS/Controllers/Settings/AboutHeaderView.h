//
//  AboutHeaderView.h
//  iNaturalist
//
//  Created by Alex Shepard on 6/13/18.
//  Copyright © 2018 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AboutHeaderView : UIView
NS_ASSUME_NONNULL_BEGIN

+ (nullable instancetype)fromXib;
@property IBOutlet UILabel *headerTitleLabel;
@property IBOutlet UILabel *headerBodyLabel;

NS_ASSUME_NONNULL_END
@end
