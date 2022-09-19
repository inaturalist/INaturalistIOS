//
//  ExploreActiveSearchView.h
//  Explore Prototype
//
//  Created by Alex Shepard on 10/5/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ActiveSearchTextDelegate
- (NSString *)activeSearchText;
@end

@interface ExploreActiveSearchView : UIView

@property UILabel *activeSearchLabel;
@property UIButton *removeActiveSearchButton;
@property (nonatomic, assign) id <ActiveSearchTextDelegate> activeSearchTextDelegate;

@end

