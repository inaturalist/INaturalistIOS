//
//  ProjectDetailV2ViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/23/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

@import AFNetworking;
@import FontAwesomeKit;
@import MBProgressHUD;
@import UIColor_HTMLColors;

#import "ProjectDetailV2ViewController.h"
#import "ProjectDetailPageViewController.h"
#import "ObsDetailV2ViewController.h"
#import "TaxonDetailViewController.h"
#import "INaturalistAppDelegate.h"
#import "Analytics.h"
#import "ProjectAboutViewController.h"
#import "SiteNewsViewController.h"
#import "UIImage+INaturalist.h"
#import "OnboardingLoginViewController.h"
#import "INatReachability.h"
#import "ProjectsAPI.h"
#import "ExploreProject.h"
#import "ExploreProjectRealm.h"
#import "LoginController.h"
#import "ExploreUserRealm.h"

@interface ProjectDetailV2ViewController ()

@property IBOutlet UIView *projectHeader;
@property IBOutlet UILabel *projectNameLabel;
@property IBOutlet UIImageView *projectThumbnail;
@property IBOutlet UIImageView *projectHeaderBackground;

@property IBOutlet UIButton *joinButton;
@property IBOutlet UIButton *newsButton;
@property IBOutlet UIButton *aboutButton;

@property IBOutlet UIView *container;

@end

@implementation ProjectDetailV2ViewController

- (ProjectsAPI *)projectsApi {
    static ProjectsAPI *_api = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _api = [[ProjectsAPI alloc] init];
    });
    return _api;
}

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
    
    [self.newsButton setTitle:[NSLocalizedString(@"News",a @"News project button") uppercaseString]
                     forState:UIControlStateNormal];
    self.newsButton.layer.cornerRadius = 15.0f;
    
    if (self.project.iconUrl) {
        [self.projectThumbnail setImageWithURL:self.project.iconUrl];
    } else {
        self.projectThumbnail.image = [UIImage inat_defaultProjectImage];
    }
    
    if (self.project.bannerImageUrl) {
        [self.projectHeaderBackground setImageWithURL:self.project.bannerImageUrl];
    }
    
    if (self.project.bannerColor) {
        self.projectHeader.backgroundColor = self.project.bannerColor;
    } else {
        self.projectHeader.backgroundColor = [UIColor whiteColor];
    }
    
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
        
    // our extremely custom navbar styling, just for this screen
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
    
    // reset our non-standard navbar
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    [self.navigationController.navigationBar setBackgroundImage:nil
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = nil;
}

- (void)inat_performSegueWithIdentifier:(NSString *)identifier object:(id)object {
    [self performSegueWithIdentifier:identifier sender:object];
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
    
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([appDelegate.loginController.meUserLocal hasJoinedProjectWithId:self.project.projectId]) {
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
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([appDelegate.loginController.meUserLocal hasJoinedProjectWithId:self.project.projectId]) {
        [self.joinButton setTitle:[NSLocalizedString(@"Leave", @"Leave project button") uppercaseString]
                         forState:UIControlStateNormal];
    } else {
        [self.joinButton setTitle:[NSLocalizedString(@"Join", @"Join project button") uppercaseString]
                         forState:UIControlStateNormal];
    }
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
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = NSLocalizedString(@"Joining...",nil);
    hud.removeFromSuperViewOnHide = YES;
    hud.dimBackground = YES;

    __weak typeof(self) weakSelf = self;
    [[self projectsApi] joinProject:self.project.projectId
                            handler:^(NSArray *results, NSInteger count, NSError *error) {
        
        [hud hide:YES];
        
        if (error) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                                           message:error.localizedDescription
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                      style:UIAlertActionStyleDefault
                                                    handler:nil]];
            [weakSelf presentViewController:alert animated:YES completion:nil];
        } else {
            RLMRealm *realm = [RLMRealm defaultRealm];
            
            if ([weakSelf.project isKindOfClass:[ExploreProject class]]) {
                ExploreProject *ep = (ExploreProject *)weakSelf.project;
                // make this project in realm, set joined to true
                NSDictionary *value = [ExploreProjectRealm valueForMantleModel:ep];
                [realm beginWriteTransaction];
                ExploreProjectRealm *epr = [ExploreProjectRealm createOrUpdateInDefaultRealmWithValue:value];
                [realm commitWriteTransaction];

                // set self.project pointer to the new realm project
                weakSelf.project = epr;
                
                INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
                [realm beginWriteTransaction];
                [appDelegate.loginController.meUserLocal.joinedProjects addObject:epr];
                [realm commitWriteTransaction];
            } else if ([weakSelf.project isKindOfClass:[ExploreProjectRealm class]]) {
                // update this project in realm
                RLMRealm *realm = [RLMRealm defaultRealm];
                INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
                [realm beginWriteTransaction];
                [appDelegate.loginController.meUserLocal.joinedProjects addObject:(ExploreProjectRealm *)weakSelf.project];
                [realm commitWriteTransaction];
            }
            
            [self configureJoinButton];
        }
        
    }];
}

- (void)leave {
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.labelText = NSLocalizedString(@"Leaving...",nil);
    hud.removeFromSuperViewOnHide = YES;
    hud.dimBackground = YES;

    __weak typeof(self) weakSelf = self;
    [[self projectsApi] leaveProject:self.project.projectId
                             handler:^(NSArray *results, NSInteger count, NSError *error) {
        
        [hud hide:YES];
        
        if (error) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                                           message:error.localizedDescription
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                      style:UIAlertActionStyleDefault
                                                    handler:nil]];
            [weakSelf presentViewController:alert animated:YES completion:nil];
        } else {
            ExploreProjectRealm *projectToLeave = (ExploreProjectRealm *)self.project;
            RLMRealm *realm = [RLMRealm defaultRealm];
            // update this project in realm
            INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
            NSInteger indexOfProjectToLeave = [appDelegate.loginController.meUserLocal.joinedProjects indexOfObject:projectToLeave];
            [realm beginWriteTransaction];
            [appDelegate.loginController.meUserLocal.joinedProjects removeObjectAtIndex:indexOfProjectToLeave];
            [realm commitWriteTransaction];

            [self configureJoinButton];
        }
    }];
}


@end
