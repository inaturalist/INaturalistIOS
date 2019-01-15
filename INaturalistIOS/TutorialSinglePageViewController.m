//
//  TutorialSinglePageViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/9/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import "TutorialSinglePageViewController.h"
#import "UIColor+ExploreColors.h"
#import "UIViewController+INaturalist.h"

@interface TutorialLabel : UILabel
@property UIEdgeInsets textInsets;
@end

@implementation TutorialLabel
- (void)drawTextInRect:(CGRect)rect {
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, self.textInsets)];
}
@end

@interface TutorialSinglePageViewController () {
    UILabel *titleLabel, *subtitleOneLabel, *subtitleTwoLabel;
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
        // title label is full bleed because it has a background color
        // but the text should not fleed to the edge.
        TutorialLabel *label = [[TutorialLabel alloc] initWithFrame:CGRectZero];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        
        label.textInsets = UIEdgeInsetsMake(0, 5, 0, 5);
        
        label.numberOfLines = 0;
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont boldSystemFontOfSize:20];
        label.backgroundColor = [UIColor inatGreen];
        label.textColor = [UIColor whiteColor];
        
        label;
    });
    [self.view addSubview:titleLabel];
    
    subtitleOneLabel = ({
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.translatesAutoresizingMaskIntoConstraints = NO;

        label.numberOfLines = 0;
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:16];
        label.textColor = [UIColor grayColor];
        
        // since we're using intrinsic height, on iOS7 UIImageView seems to
        // have higher built-in priority than this label
        [label setContentCompressionResistancePriority:UILayoutPriorityRequired
                                               forAxis:UILayoutConstraintAxisVertical];
        
        label;
    });
    [self.view addSubview:subtitleOneLabel];
    
    tutorialImageView = ({
        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectZero];
        iv.translatesAutoresizingMaskIntoConstraints = NO;
        
        [iv setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh
                                            forAxis:UILayoutConstraintAxisVertical];
        iv.contentMode = UIViewContentModeScaleAspectFit;
        
        iv;
    });
    [self.view addSubview:tutorialImageView];
    
    subtitleTwoLabel = ({
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.translatesAutoresizingMaskIntoConstraints = NO;

        label.numberOfLines = 0;
        label.textAlignment = NSTextAlignmentCenter;
        label.font = [UIFont systemFontOfSize:16];
        label.textColor = [UIColor grayColor];
        
        // since we're using intrinsic height, on iOS7 UIImageView seems to
        // have higher built-in priority than this label
        [label setContentCompressionResistancePriority:UILayoutPriorityRequired
                                               forAxis:UILayoutConstraintAxisVertical];
        
        
        label;
    });
    [self.view addSubview:subtitleTwoLabel];

    
    okButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        
        [button setTitle:NSLocalizedString(@"Got It", @"Button to dismiss a tutorial screen")
                forState:UIControlStateNormal];
        
        [button addTarget:self
                   action:@selector(tappedOk)
         forControlEvents:UIControlEventTouchUpInside];
        
        button.backgroundColor = [UIColor grayColor];
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
        
        button.backgroundColor = [UIColor whiteColor];
        button.tintColor = [UIColor grayColor];
        
        button;
    });
    [self.view addSubview:neverAgainButton];
    
    // autolayout
    UILayoutGuide *safeGuide = [self inat_safeLayoutGuide];
    
    // horizontal
    [titleLabel.leadingAnchor constraintEqualToAnchor:safeGuide.leadingAnchor].active = YES;
    [titleLabel.trailingAnchor constraintEqualToAnchor:safeGuide.trailingAnchor].active = YES;
    [tutorialImageView.leadingAnchor constraintEqualToAnchor:safeGuide.leadingAnchor].active = YES;
    [tutorialImageView.trailingAnchor constraintEqualToAnchor:safeGuide.trailingAnchor].active = YES;
    [subtitleOneLabel.leadingAnchor constraintEqualToAnchor:safeGuide.leadingAnchor].active = YES;
    [subtitleOneLabel.trailingAnchor constraintEqualToAnchor:safeGuide.trailingAnchor].active = YES;
    [subtitleTwoLabel.leadingAnchor constraintEqualToAnchor:safeGuide.leadingAnchor].active = YES;
    [subtitleTwoLabel.trailingAnchor constraintEqualToAnchor:safeGuide.trailingAnchor].active = YES;
    [okButton.leadingAnchor constraintEqualToAnchor:safeGuide.leadingAnchor].active = YES;
    [okButton.trailingAnchor constraintEqualToAnchor:safeGuide.trailingAnchor].active = YES;
    [neverAgainButton.leadingAnchor constraintEqualToAnchor:safeGuide.leadingAnchor].active = YES;
    [neverAgainButton.trailingAnchor constraintEqualToAnchor:safeGuide.trailingAnchor].active = YES;
    
    // vertical
    [titleLabel.topAnchor constraintEqualToAnchor:safeGuide.topAnchor constant:22.0f].active = YES;
    [titleLabel.bottomAnchor constraintEqualToAnchor:subtitleOneLabel.topAnchor].active = YES;
    [subtitleOneLabel.bottomAnchor constraintEqualToAnchor:tutorialImageView.topAnchor].active = YES;
    [tutorialImageView.bottomAnchor constraintEqualToAnchor:subtitleTwoLabel.topAnchor].active = YES;
    [subtitleTwoLabel.bottomAnchor constraintEqualToAnchor:okButton.topAnchor].active = YES;
    [okButton.bottomAnchor constraintEqualToAnchor:neverAgainButton.topAnchor].active = YES;
    [neverAgainButton.bottomAnchor constraintEqualToAnchor:safeGuide.bottomAnchor].active = YES;
    
    [titleLabel.heightAnchor constraintEqualToConstant:88.0f].active = YES;
    [subtitleTwoLabel.heightAnchor constraintEqualToAnchor:subtitleOneLabel.heightAnchor].active = YES;
    [okButton.heightAnchor constraintEqualToConstant:44.0f].active = YES;
    [neverAgainButton.heightAnchor constraintEqualToConstant:44.0f].active = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    tutorialImageView.image = self.tutorialImage;
    titleLabel.text = self.tutorialTitle;
    subtitleOneLabel.text = self.tutorialSubtitleOne;
    subtitleTwoLabel.text = self.tutorialSubtitleTwo;
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



