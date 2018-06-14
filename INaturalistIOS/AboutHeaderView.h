//
//  AboutHeaderView.h
//  iNaturalist
//
//  Created by Alex Shepard on 6/13/18.
//  Copyright © 2018 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AboutHeaderView : UIView
+ (instancetype)fromXib;
@property IBOutlet UILabel *headerTitleLabel;
@property IBOutlet UIImageView *casLogo;
@property IBOutlet UIImageView *ngsLogo;
@property IBOutlet UILabel *headerBodyLabel;
@end
