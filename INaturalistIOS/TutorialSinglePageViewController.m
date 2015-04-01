//
//  TutorialSinglePageViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/9/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import "TutorialSinglePageViewController.h"
#import "UIColor+ExploreColors.h"

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
    
    NSDictionary *views = @{
                            @"title": titleLabel,
                            @"neverAgain": neverAgainButton,
                            @"ok": okButton,
                            @"image": tutorialImageView,
                            @"subtitleOne": subtitleOneLabel,
                            @"subtitleTwo": subtitleTwoLabel,
                            };
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-22-[title(==88)]-[subtitleOne]-[image]-[subtitleTwo(==subtitleOne)]-[ok(==44)]-0-[neverAgain(==44)]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[title]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[image]-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[subtitleOne]-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[subtitleTwo]-|"
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



