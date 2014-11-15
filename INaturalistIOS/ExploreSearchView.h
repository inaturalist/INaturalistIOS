//
//  ExploreSearchView.h
//  iNaturalist
//
//  Created by Alex Shepard on 11/12/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ActiveSearchTextDelegate;

@class ExploreActiveSearchView;

@interface ExploreSearchView : UIView


@property NSArray *autocompleteItems;
@property NSArray *shortcutItems;

@property ExploreActiveSearchView *activeSearchFilterView;
@property (nonatomic, assign) id <ActiveSearchTextDelegate> activeSearchTextDelegate;

- (void)hideOptionSearch;
- (void)showOptionSearch;
- (BOOL)optionSearchIsActive;

- (void)showActiveSearch;
- (void)hideActiveSearch;


@end

@protocol ActiveSearchTextDelegate
- (NSString *)activeSearchText;
@end
