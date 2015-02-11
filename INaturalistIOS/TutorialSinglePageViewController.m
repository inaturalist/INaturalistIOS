//
//  TutorialSinglePageViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/9/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import "TutorialSinglePageViewController.h"
#import "UIColor+ExploreColors.h"

@interface TutorialSinglePageViewController () {
    UILabel *titleLabel;
    UIImageView *tutorialImageView;
    UIButton *okButton;
    UIButton *neverAgainButton;
}

@end

@implementation TutorialSinglePageViewController

#pragma mark - UIViewController lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    titleLabel = ({
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        
        label.numberOfLines = 0;
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont boldSystemFontOfSize:24.0f];
        label.backgroundColor = [UIColor inatGreen];
        label.textColor = [UIColor whiteColor];
        
        label;
    });
    [self.view addSubview:titleLabel];
    
    tutorialImageView = ({
        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectZero];
        iv.translatesAutoresizingMaskIntoConstraints = NO;
        
        iv.contentMode = UIViewContentModeScaleAspectFit;
        
        iv;
    });
    [self.view addSubview:tutorialImageView];
    
    okButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        
        [button setTitle:NSLocalizedString(@"Got It", @"Button to dismiss a tutorial screen")
                forState:UIControlStateNormal];
        
        [button addTarget:self
                   action:@selector(tappedOk)
         forControlEvents:UIControlEventTouchUpInside];
        
        button.backgroundColor = [UIColor colorForIconicTaxon:@"Animals"];  // iNat blue
        button.tintColor = [UIColor whiteColor];
        
        button;
    });
    [self.view addSubview:okButton];
    
    neverAgainButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        
        [button setTitle:NSLocalizedString(@"Don't Show Me Hints", @"Button to cancel showing tutorial screens when visiting new tabs")
                forState:UIControlStateNormal];
        
        [button addTarget:self
                   action:@selector(tappedNeverAgain)
         forControlEvents:UIControlEventTouchUpInside];
        
        button.backgroundColor = [UIColor colorForIconicTaxon:@"Insecta"];  // iNat red
        button.tintColor = [UIColor blackColor];
        
        button;
    });
    [self.view addSubview:neverAgainButton];
    
    NSDictionary *views = @{
                            @"title": titleLabel,
                            @"neverAgain": neverAgainButton,
                            @"ok": okButton,
                            @"tutorial": tutorialImageView,
                            };
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-22-[title(==88)]-0-[tutorial]-0-[ok(==44)]-0-[neverAgain(==44)]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[title]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[tutorial]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[ok]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[neverAgain]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];

}

- (void)viewWillAppear:(BOOL)animated {
    tutorialImageView.image = self.tutorialImage;
    titleLabel.text = self.tutorialTitle;
}

#pragma mark - UIButton targets

- (void)tappedOk {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)tappedNeverAgain {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kDefaultsKeyTutorialNeverAgain];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end


NSString *kDefaultsKeyTutorialNeverAgain = @"DefaultsKeyNeverShowTutorialScreensAgain";
NSString *kDefaultsKeyTutorialSeenNewObs = @"DefaultsKeySeenTutorialNewObs";
NSString *kDefaultsKeyTutorialSeenEditObs = @"DefaultsKeySeenTutorialEditObs";
NSString *kDefaultsKeyTutorialSeenNewObsCommunity = @"DefaultsKeySeenTutorialNewObsCommunity";
NSString *kDefaultsKeyTutorialSeenExplore = @"DefaultsKeySeenTutorialExplore";
NSString *kDefaultsKeyTutorialSeenProjects = @"DefaultsKeySeenTutorialProjects";
NSString *kDefaultsKeyTutorialSeenGuides = @"DefaultsKeySeenTutorialGuides";
NSString *kDefaultsKeyOldTutorialSeen = @"tutorialSeen";



