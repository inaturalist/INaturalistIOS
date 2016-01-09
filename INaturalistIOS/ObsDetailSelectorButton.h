//
//  ObsDetailSelectorButton.h
//  iNaturalist
//
//  Created by Alex Shepard on 12/10/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, ObsDetailSelectorButtonType) {
    ObsDetailSelectorButtonTypeInfo,
    ObsDetailSelectorButtonTypeActivity,
    ObsDetailSelectorButtonTypeFaves
};


@interface ObsDetailSelectorButton : UIButton

+ (instancetype)buttonWithSelectorType:(ObsDetailSelectorButtonType)type;

@property NSInteger count;

@end
