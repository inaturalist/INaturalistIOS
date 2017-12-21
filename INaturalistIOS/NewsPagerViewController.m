//
//  NewsPagerViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 10/21/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <UIColor-HTMLColors/UIColor+HTMLColors.h>
#import <FontAwesomeKit/FAKIonIcons.h>

#import "NewsPagerViewController.h"
#import "UIColor+INaturalist.h"
#import "SiteNewsViewController.h"
#import "UpdatesViewController.h"
#import "INaturalistAppDelegate.h"
#import "LoginController.h"
#import "INatUITabBarController.h"

@interface NewsPagerViewController () <ViewPagerDelegate, ViewPagerDataSource>
@end

@implementation NewsPagerViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.title = NSLocalizedString(@"Activity", nil);
        
        self.tabBarItem.image = ({
            FAKIcon *newsInactive = [FAKIonIcons iosBellIconWithSize:35];
            [newsInactive addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor]];
            [[newsInactive imageWithSize:CGSizeMake(34, 45)] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        });
        
        self.tabBarItem.selectedImage = ({
            FAKIcon *newsActive = [FAKIonIcons iosBellIconWithSize:35];
            [newsActive addAttribute:NSForegroundColorAttributeName value:[UIColor inatTint]];
            [[newsActive imageWithSize:CGSizeMake(34, 45)] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        });
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.dataSource = self;
    self.delegate = self;
    
    NSInteger selectedTab = 0;
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (![[appDelegate loginController] isLoggedIn] || ![[NSUserDefaults standardUserDefaults] boolForKey:HasMadeAnObservationKey]) {
        selectedTab = 1;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self selectTabAtIndex:selectedTab];
    });
    
    self.siteNews = [self.storyboard instantiateViewControllerWithIdentifier:@"SiteNewsViewController"];
    self.updates = [self.storyboard instantiateViewControllerWithIdentifier:@"UpdatesViewController"];
    
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    __weak typeof(self)weakSelf = self;
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [weakSelf setNeedsReloadOptions];
        [weakSelf reloadData];
    } completion:nil];
}

#pragma mark - UIViewPagerDelegate

-(CGFloat)viewPager:(ViewPagerController *)viewPager valueForOption:(ViewPagerOption)option withDefault:(CGFloat)value {
    switch (option) {
        case ViewPagerOptionCenterCurrentTab:
            return 1.0f;
            break;
        case ViewPagerOptionTabHeight:
            // since we're not below the navigation bar anymore,
            // we have to accommodate the status bar
            return 20 + 52;
            break;
        case ViewPagerOptionTabWidth:
            return self.parentViewController.view.frame.size.width / 2.0f;
            break;
        default:
            return value;
            break;
    }
}

#pragma mark - UIViewPagerDataSource

- (NSUInteger)numberOfTabsForViewPager:(ViewPagerController *)viewPager {
    return 2;
}

- (UIColor *)viewPager:(ViewPagerController *)viewPager colorForComponent:(ViewPagerComponent)component withDefault:(UIColor *)color {
    switch (component ) {
        case ViewPagerIndicator:
            return [UIColor inatTint];
        case ViewPagerContent:
            return color;
        case ViewPagerTabsView:
            return [UIColor whiteColor];
    }
}

- (UIView *)viewPager:(ViewPagerController *)viewPager viewForTabAtIndex:(NSUInteger)index {
    
    UIView *tab = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.parentViewController.view.frame.size.width / 2.0f, 60.0f)];
    
    CGFloat width = self.parentViewController.view.frame.size.width / 2.0f;
    if (index < 1) {
        width = width - 0.5f;
    }
    UILabel *label = [UILabel new];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.numberOfLines = 2;
    label.textAlignment = NSTextAlignmentCenter;
    
    NSInteger *count;
    
    switch (index) {
        case 0:
            label.text = NSLocalizedString(@"My Content", nil);
            break;
        case 1:
            label.text = NSLocalizedString(@"News", nil);
            break;
        default:
            count = 0;
            label.text = @"";
            break;
    }
    
    label.font = [UIFont systemFontOfSize:17.0f weight:UIFontWeightMedium];
    [tab addSubview:label];
    
    UIView *separator = [UIView new];
    separator.translatesAutoresizingMaskIntoConstraints = NO;
    separator.backgroundColor = [UIColor colorWithHexString:@"#efeff4"];
    [tab addSubview:separator];
    separator.hidden = (index > 0);
    
    NSDictionary *views = @{
                            @"separator": separator,
                            @"label": label,
                            };
    
    [tab addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[label]|"
                                                                options:0
                                                                metrics:0
                                                                  views:views]];
    [tab addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"[separator(==0.5)]|"
                                                                options:0
                                                                metrics:0
                                                                  views:views]];
    
    [tab addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[label]-12-|"
                                                                options:0
                                                                metrics:0
                                                                  views:views]];
    [tab addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[separator(==30)]-11-|"
                                                                options:0
                                                                metrics:0
                                                                  views:views]];
    
    return tab;
}

- (UIViewController *)viewPager:(ViewPagerController *)viewPager contentViewControllerForTabAtIndex:(NSUInteger)index {
    switch (index) {
        case 0:
            return self.updates;
            break;
        default:
            return self.siteNews;
            break;
    }
}


@end
