//
//  ProjectDetailV2ViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/23/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <AFNetworking/UIImageView+AFNetworking.h>
#import <FontAwesomeKit/FAKIonIcons.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <UIColor-HTMLColors/UIColor+HTMLColors.h>
#import <RestKit/RestKit.h>

#import "ProjectDetailV2ViewController.h"
#import "Project.h"
#import "ProjectUser.h"
#import "ProjectDetailPageViewController.h"
#import "ObsDetailV2ViewController.h"
#import "ContainedScrollViewDelegate.h"
#import "TaxonDetailViewController.h"
#import "INaturalistAppDelegate.h"
#import "INaturalistAppDelegate.h"
#import "Analytics.h"
#import "ProjectAboutViewController.h"
#import "SiteNewsViewController.h"
#import "UIImage+INaturalist.h"
#import "ProjectNewsButton.h"
#import "OnboardingLoginViewController.h"
#import "INatReachability.h"

// At this offset the Header stops its transformations
// 200 is the height of the header
// 44 is the height of the navbar
// 20 is the height of the status bar
static CGFloat OffsetHeaderStop = 200 - 44 - 20;

@interface ProjectDetailV2ViewController () <ContainedScrollViewDelegate, RKObjectLoaderDelegate>

@property IBOutlet UIView *projectHeader;
@property IBOutlet UILabel *projectNameLabel;
@property IBOutlet UIImageView *projectThumbnail;
@property IBOutlet UIImageView *projectHeaderBackground;

@property IBOutlet UIButton *joinButton;
@property IBOutlet ProjectNewsButton *newsButton;
@property IBOutlet UIButton *aboutButton;

@property IBOutlet UIView *container;

@property ProjectUser *projectUser;

@end

@implementation ProjectDetailV2ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController.navigationBar setTitleTextAttributes:@{
                                                                      NSFontAttributeName: [UIFont systemFontOfSize:17],
                                                                      NSForegroundColorAttributeName: [UIColor whiteColor],
                                                                      }];
    
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
    effectView.frame = self.projectHeaderBackground.bounds;
    effectView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    [self.projectHeaderBackground addSubview:effectView];
    
    [self.projectHeaderBackground removeFromSuperview];
    self.projectHeaderBackground.clipsToBounds = YES;
    [self.projectHeader insertSubview:self.projectHeaderBackground atIndex:0];
    
    self.projectThumbnail.layer.cornerRadius = 2.0f;
    self.projectThumbnail.layer.borderColor = [UIColor whiteColor].CGColor;
    self.projectThumbnail.layer.borderWidth = 1.0f;
    
    [self.joinButton setTitle:[NSLocalizedString(@"Join", @"Join project button") uppercaseString]
                     forState:UIControlStateNormal];
    self.joinButton.layer.cornerRadius = 15.0f;
    [self.aboutButton setTitle:[NSLocalizedString(@"About", @"About project button") uppercaseString]
                      forState:UIControlStateNormal];
    self.aboutButton.layer.cornerRadius = 15.0f;
    
    self.newsButton.newsTextLabel.text = [NSLocalizedString(@"News",a @"News project button") uppercaseString];
    self.newsButton.layer.cornerRadius = 15.0f;
    [self configureNewsButton];
    
    NSURL *projectThumbUrl = [NSURL URLWithString:self.project.iconURL];
    if (projectThumbUrl) {
        [self.projectThumbnail setImageWithURL:projectThumbUrl];
        [self.projectHeaderBackground setImageWithURL:projectThumbUrl];
    } else {
        self.projectThumbnail.image = [UIImage inat_defaultProjectImage];
        self.projectThumbnail.backgroundColor = [UIColor whiteColor];
    }
    
    self.projectHeader.backgroundColor = [UIColor whiteColor];
    
    self.projectNameLabel.text = self.project.title;
    
    FAKIcon *backIcon = [FAKIonIcons iosArrowBackIconWithSize:25];
    [backIcon addAttribute:NSForegroundColorAttributeName
                     value:[UIColor whiteColor]];
    FAKIcon *circle = [FAKIonIcons recordIconWithSize:40];
    [circle addAttribute:NSForegroundColorAttributeName
                   value:[[UIColor whiteColor] colorWithAlphaComponent:0.4f]];
    
    UIImage *backImage = [[UIImage imageWithStackedIcons:@[ backIcon, circle ]
                                               imageSize:CGSizeMake(40, 40)] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:backImage
                                                                             style:UIBarButtonItemStyleDone
                                                                            target:self
                                                                            action:@selector(myBack)];
    
    self.projectUser = [ProjectUser objectWithPredicate:[NSPredicate predicateWithFormat:@"projectID = %@", self.project.recordID]];
    
    [self.joinButton addTarget:self
                        action:@selector(joinTapped:)
              forControlEvents:UIControlEventTouchUpInside];
    [self.newsButton addTarget:self
                        action:@selector(newsTapped:)
              forControlEvents:UIControlEventTouchUpInside];
    [self.aboutButton addTarget:self
                         action:@selector(aboutTapped:)
               forControlEvents:UIControlEventTouchUpInside];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"containerSegueToViewPager"]) {
        ProjectDetailPageViewController *vc = [segue destinationViewController];
        vc.projectDetailDelegate = self;
        vc.containedScrollViewDelegate = self;
        vc.project = self.project;
    } else if ([segue.identifier isEqualToString:@"segueToObservationDetail"]) {
        ObsDetailV2ViewController *vc = [segue destinationViewController];
        vc.observation = sender;
        [[Analytics sharedClient] event:kAnalyticsEventNavigateObservationDetail
                         withProperties:@{ @"via": @"Project Details" }];
    } else if ([segue.identifier isEqualToString:@"taxon"]) {
        TaxonDetailViewController *vc = [segue destinationViewController];
        vc.taxon = sender;
    } else if ([segue.identifier isEqualToString:@"projectAboutSegue"]) {
        ProjectAboutViewController *vc = [segue destinationViewController];
        vc.project = self.project;
    } else if ([segue.identifier isEqualToString:@"projectNewsSegue"]) {
        SiteNewsViewController *vc = [segue destinationViewController];
        vc.project = self.project;
    }
}

- (void)myBack {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // re-fetch the project to make sure we're getting an updated news item count
    NSString *path = [NSString stringWithFormat:@"/projects/%ld.json", (long)self.project.recordID.integerValue];
    __weak typeof(self) weakSelf = self;
    [[RKObjectManager sharedManager] loadObjectsAtResourcePath:path usingBlock:^(RKObjectLoader *loader) {
        
        loader.objectMapping = [Project mapping];
        loader.onDidLoadObject = ^(id object) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            NSDate *now = [NSDate date];
            [object setSyncedAt:now];
            
            NSError *error = nil;
            [[[RKObjectManager sharedManager] objectStore] save:&error];
            if (error) {
                NSString *logMsg = [NSString stringWithFormat:@"SAVE ERROR: %@", error.localizedDescription];
                [[Analytics sharedClient] debugLog:logMsg];
            }
            
            strongSelf.project = (Project *)object;
            [strongSelf configureNewsButton];
        };
    }];
    
    [UIView animateWithDuration:0.3f
                     animations:^{
                         [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                                       forBarMetrics:UIBarMetricsDefault];
                         self.navigationController.navigationBar.shadowImage = [UIImage new];
                         self.navigationController.navigationBar.translucent = YES;
                     } completion:^(BOOL finished) {
                         self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
                     }];
    
    [self.navigationController setToolbarHidden:YES animated:YES];
    
    [self.navigationController.navigationBar setTitleTextAttributes:@{
                                                                      NSFontAttributeName: [UIFont systemFontOfSize:17],
                                                                      NSForegroundColorAttributeName: [UIColor whiteColor],
                                                                      }];
    
    [self configureJoinButton];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.navigationController.navigationBar setTitleTextAttributes:@{
                                                                      NSFontAttributeName: [UIFont boldSystemFontOfSize:17],
                                                                      NSForegroundColorAttributeName: [UIColor blackColor],
                                                                      }];
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
}

- (void)inat_performSegueWithIdentifier:(NSString *)identifier object:(id)object {
    [self performSegueWithIdentifier:identifier sender:object];
}

- (void)dealloc {
    [[[RKClient sharedClient] requestQueue] cancelRequestsWithDelegate:self];
}

#pragma mark - Contained Scroll View Delegate

- (void)containedScrollViewDidStopScrolling:(UIScrollView *)scrollView {
    CGFloat offset = scrollView.contentOffset.y;
    
    if (offset > 0 && offset < OffsetHeaderStop) {
        [scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
    }
}

- (void)containedScrollViewDidReset:(UIScrollView *)scrollView {
    [UIView animateWithDuration:0.3 animations:^{
        self.projectHeader.layer.transform = CATransform3DIdentity;
        self.container.frame = CGRectMake(0,
                                          200,
                                          self.view.bounds.size.width,
                                          self.view.bounds.size.height - self.projectHeader.frame.size.height);
        for (UIButton *btn in @[ self.joinButton, self.newsButton, self.aboutButton ]) {
            btn.alpha = 1.0f;
            btn.userInteractionEnabled = YES;
        }
        
        self.title = nil;
        self.projectNameLabel.alpha = 1.0f;
    }];
}

- (void)containedScrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat offset = scrollView.contentOffset.y;
    CATransform3D headerTransform = CATransform3DIdentity;
    
    if (offset <= 0) {
        CGFloat newAlpha = 1.0f;
        for (UIButton *btn in @[ self.joinButton, self.newsButton, self.aboutButton ]) {
            btn.alpha = newAlpha;
            btn.userInteractionEnabled = YES;
        }
        self.container.frame = CGRectMake(0,
                                          200,
                                          self.view.bounds.size.width,
                                          self.view.bounds.size.height - self.projectHeader.frame.size.height);
    } else {
        CGFloat tz = MAX(-OffsetHeaderStop, -offset);
        
        // if offset is greater than 86, button alpha is 0.0
        // if offset is less than 0, button alpha is 1.0
        // if offset is between 0 and 86, button alpha is (1.0 - offset / 86)
        
        CGFloat newAlpha = 0.0;
        if (offset > 86) {
            newAlpha = 0.0f;
        } else if (offset < 0.0f) {
            newAlpha = 1.0f;
        } else {
            newAlpha = 1.0 - (offset / 86);
        }
        for (UIButton *btn in @[ self.joinButton, self.newsButton, self.aboutButton ]) {
            btn.alpha = newAlpha;
            btn.userInteractionEnabled = (newAlpha > 0.99f);
        }
        
        // if offset is greater than 86, title center is equal to navbar center
        if (offset > 86) {
            if (self.projectNameLabel.alpha != 0) {
                self.projectNameLabel.alpha = 0.0f;
                self.title = self.projectNameLabel.text;
            }
        } else {
            if (self.projectNameLabel.alpha != 1.0f) {
                self.projectNameLabel.alpha = 1.0f;
                self.title = nil;
            }
        }
        
        headerTransform = CATransform3DTranslate(headerTransform, 0, tz, 0);
        self.container.frame = CGRectMake(0,
                                          200 + tz,
                                          self.view.bounds.size.width,
                                          self.view.bounds.size.height - 200 - tz);
    }
    self.projectHeader.layer.transform = headerTransform;
}

#pragma mark - UIButton targets

- (void)joinTapped:(UIButton *)button {
    if (![[INatReachability sharedClient] isNetworkReachable]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Internet required", nil)
                                                                       message:NSLocalizedString(@"You must be connected to the Internet to do this.", nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];        
        return;
    }
    
    if (self.projectUser && self.projectUser.syncedAt) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Are you sure you want to leave this project?", nil)
                                                                       message:NSLocalizedString(@"This will also remove your observations from this project.",nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Leave", nil)
                                                  style:UIAlertActionStyleDestructive
                                                handler:^(UIAlertAction * _Nonnull action) {
                                                    [self leave];
                                                }]];
        [self presentViewController:alert animated:YES completion:nil];
    } else {
        if ([(INaturalistAppDelegate *)UIApplication.sharedApplication.delegate loggedIn]) {
            [self join];
        } else {
            [self presentSignupPrompt:NSLocalizedString(@"You must be signed in to join a project.", @"Reason text for signup prompt while trying to join a project.")];
        }
    }
}

- (void)newsTapped:(UIButton *)button {
    [self performSegueWithIdentifier:@"projectNewsSegue" sender:self.project];
}

- (void)aboutTapped:(UIButton *)button {
    [self performSegueWithIdentifier:@"projectAboutSegue" sender:self.project];
}

- (void)configureJoinButton {
    if (self.projectUser) {
        [self.joinButton setTitle:[NSLocalizedString(@"Leave", @"Leave project button") uppercaseString]
                         forState:UIControlStateNormal];
    } else {
        [self.joinButton setTitle:[NSLocalizedString(@"Join", @"Join project button") uppercaseString]
                         forState:UIControlStateNormal];
    }
}

- (void)configureNewsButton {
    self.newsButton.countLabel.text = [NSString stringWithFormat:@"%ld", (long)self.project.newsItemCount.integerValue];
    self.newsButton.enabled = (self.project.newsItemCount.integerValue > 0);
}

- (void)presentSignupPrompt:(NSString *)reason {
    [[Analytics sharedClient] event:kAnalyticsEventNavigateOnboardingScreenLogin
                     withProperties:@{ @"via": @"project detail" }];

    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Onboarding" bundle:nil];
    OnboardingLoginViewController *login = [storyboard instantiateViewControllerWithIdentifier:@"onboarding-login"];
    login.skippable = NO;
    [self presentViewController:login animated:YES completion:nil];
}

#pragma mark - Project Actions

- (void)join {
    [[Analytics sharedClient] debugLog:@"Network - Join a project"];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = NSLocalizedString(@"Joining...",nil);
    hud.removeFromSuperViewOnHide = YES;
    hud.dimBackground = YES;
    
    if (!self.projectUser) {
        self.projectUser = [ProjectUser object];
        self.projectUser.project = self.project;
        self.projectUser.projectID = self.project.recordID;
    }
    [[RKObjectManager sharedManager] postObject:self.projectUser usingBlock:^(RKObjectLoader *loader) {
        loader.delegate = self;
        loader.resourcePath = [NSString stringWithFormat:@"/projects/%d/join", self.project.recordID.intValue];
        loader.objectMapping = [ProjectUser mapping];
    }];
}

- (void)leave {
    [[Analytics sharedClient] debugLog:@"Network - Leave a project"];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = NSLocalizedString(@"Leaving...",nil);
    hud.removeFromSuperViewOnHide = YES;
    hud.dimBackground = YES;
    
    [[RKObjectManager sharedManager] deleteObject:self.projectUser usingBlock:^(RKObjectLoader *loader) {
        loader.delegate = self;
        loader.resourcePath = [NSString stringWithFormat:@"/projects/%d/leave", self.project.recordID.intValue];
    }];
}

#pragma mark - RKObjectLoaderDelegate && RKRequestDelegate

- (void)request:(RKRequest *)request didReceiveResponse:(RKResponse *)response {
    if (request.method == RKRequestMethodDELETE) {
        if (response.statusCode == 200) {
            self.projectUser = nil;
            [self configureJoinButton];
        }
    }
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObject:(id)object {
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    });
    
    ProjectUser *pu = object;
    if (pu) {
        pu.syncedAt = [NSDate date];
        [pu save];
    }
    self.projectUser = pu;
    
    [self configureJoinButton];
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    });
    
    if (objectLoader.response.statusCode == 401) {
        [self presentSignupPrompt:NSLocalizedString(@"You must be signed in to do that.", @"Reason text for signup prompt while trying to sync a project.")];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Whoops!",nil)
                                                                       message:[NSString stringWithFormat:NSLocalizedString(@"Looks like there was an error: %@",nil), error.localizedDescription]
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}



@end
