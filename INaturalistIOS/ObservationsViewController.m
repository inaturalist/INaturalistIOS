//
//  ObservationsViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/13/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

@import ImageIO;
@import FontAwesomeKit;
@import BlocksKit;
@import CustomIOSAlertView;
@import JDStatusBarNotification;
@import UIColor_HTMLColors;
@import AFNetworking;
@import MBProgressHUD;

#import "ObservationsViewController.h"
#import "LoginController.h"
#import "ImageStore.h"
#import "INaturalistAppDelegate.h"
#import "RefreshControl.h"
#import "UIImageView+WebCache.h"
#import "UIColor+INaturalist.h"
#import "Analytics.h"
#import "MeHeaderView.h"
#import "AnonHeaderView.h"
#import "INatWebController.h"
#import "INaturalistAppDelegate.h"
#import "UploadManagerNotificationDelegate.h"
#import "ObservationViewNormalCell.h"
#import "ObservationViewUploadingCell.h"
#import "ObservationViewWaitingUploadCell.h"
#import "ObservationViewErrorCell.h"
#import "UploadManager.h"
#import "ObsDetailV2ViewController.h"
#import "ExploreTaxonRealm.h"
#import "NSURL+INaturalist.h"
#import "PeopleAPI.h"
#import "OnboardingLoginViewController.h"
#import "ExploreUpdateRealm.h"
#import "Taxon.h"
#import "INatReachability.h"
#import "NSLocale+INaturalist.h"
#import "ExploreDeletedRecord.h"
#import "YearInReviewAPI.h"
#import "ExploreObservationRealm.h"
#import "ObservationAPI.h"
#import "InaturalistRealmMigration.h"
#import "NSDate+INaturalist.h"

@interface ObservationsViewController () <UploadManagerNotificationDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MFMailComposeViewControllerDelegate>

@property MeHeaderView *meHeader;
@property AnonHeaderView *anonHeader;
@property (nonatomic, strong) NSDate *lastRefreshAt;
@property NSMutableDictionary *uploadProgress;

@property RLMResults *myObservations;
@property RLMNotificationToken *myObsNoteToken;

// this is kind of a hack because updates aren't directly attached to observations
@property RLMResults *myUpdates;
@property RLMNotificationToken *myUpdatesNoteToken;

@end

@implementation ObservationsViewController

- (ObservationAPI *)obsApi {
    static ObservationAPI *_api = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _api = [[ObservationAPI alloc] init];
    });
    return _api;
}

- (YearInReviewAPI *)yearInReviewApi {
    static YearInReviewAPI *_api = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _api = [[YearInReviewAPI alloc] init];
    });
    return _api;
}

- (PeopleAPI *)peopleApi {
    static PeopleAPI *_api = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _api = [[PeopleAPI alloc] init];
    });
    return _api;
}

- (InaturalistRealmMigration *)migrationAssistant {
    static InaturalistRealmMigration *_assistant = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _assistant = [[InaturalistRealmMigration alloc] init];
    });
    return _assistant;
}

- (void)presentLoginSplashWithReason:(NSString *)reason {
    [[Analytics sharedClient] event:kAnalyticsEventNavigateOnboardingScreenLogin
                     withProperties:@{ @"via": @"observations" }];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Onboarding" bundle:nil];
    OnboardingLoginViewController *login = [storyboard instantiateViewControllerWithIdentifier:@"onboarding-login"];
    login.skippable = NO;
    login.startsInLoginMode = YES;
    login.reason = reason;
    [self presentViewController:login animated:YES completion:nil];
}

- (void)presentSignupSplashWithReason:(NSString *)reason {
    [[Analytics sharedClient] event:kAnalyticsEventNavigateOnboardingScreenLogin
                     withProperties:@{ @"via": @"observations" }];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Onboarding" bundle:nil];
    OnboardingLoginViewController *login = [storyboard instantiateViewControllerWithIdentifier:@"onboarding-login"];
    login.skippable = NO;
    login.reason = reason;
    [self presentViewController:login animated:YES completion:nil];
}

- (void)presentAutouploadAlert {
    
    if (![UIAlertController class]) {
        return;
    }
    
    [[UIView appearanceWhenContainedInInstancesOfClasses:@[ [UIAlertController class] ]] setBackgroundColor:[UIColor inatTint]];
    
    // existing users see a one-time autoupload notice
    NSString *alertTitle = NSLocalizedString(@"Introducing Auto Upload!", @"title of autoupload introduction alert view");
    
    NSAttributedString *attrTitleText = [[NSAttributedString alloc] initWithString:alertTitle
                                                                        attributes:@{ NSForegroundColorAttributeName: [UIColor whiteColor],
                                                                                      NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0f],
                                                                        }];
    
    NSString *alertMsg = NSLocalizedString(@"Turn on Auto Upload and your observations will be automatically uploaded to iNaturalist.",
                                           @"message of autoupload introduction alert view");
    NSAttributedString *attrMsg = [[NSAttributedString alloc] initWithString:alertMsg
                                                                  attributes:@{ NSForegroundColorAttributeName: [UIColor whiteColor] }];
    
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@""
                                                                   message:@""
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    [alert setValue:attrTitleText forKey:@"attributedTitle"];
    [alert setValue:attrMsg forKey:@"attributedMessage"];
    
    // sets the color of the alert action cells only
    alert.view.tintColor = [UIColor whiteColor];
    
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"No Thanks", nil)
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Turn On", @"button title to turn on autoupload")
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action) {
        // enable the autoupload setting
        [[NSUserDefaults standardUserDefaults] setBool:YES
                                                forKey:kInatAutouploadPrefKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // kick off autoupload if appropriate
        INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
        UploadManager *uploadManager = appDelegate.loginController.uploadManager;
        if ([uploadManager shouldAutoupload]) {
            if (uploadManager.isNetworkAvailableForUpload) {
                [uploadManager autouploadPendingContent];
            } else {
                if (uploadManager.shouldNotifyAboutNetworkState) {
                    [JDStatusBarNotification showWithStatus:NSLocalizedString(@"Network Unavailable", nil)
                                               dismissAfter:4];
                }
            }
        }
        
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }]];
    [self.navigationController presentViewController:alert animated:YES completion:^{
        [[UIView appearanceWhenContainedInInstancesOfClasses:@[ [UIAlertController class] ]] setBackgroundColor:nil];
    }];
    
}

- (void)uploadOneObservation:(UIButton *)button {
    CGPoint buttonCenter = button.center;
    CGPoint translatedCenter = [self.tableView convertPoint:buttonCenter fromView:button.superview];
    NSIndexPath *ip = [self.tableView indexPathForRowAtPoint:translatedCenter];
    
    id <Uploadable> observation = [self.myObservations objectAtIndex:ip.item];
    
    [[Analytics sharedClient] event:kAnalyticsEventSyncObservation
                     withProperties:@{
                         @"Via": @"Manual Single Upload",
                         @"numDeletes": @(0),
                         @"numUploads": @(1),
                     }];
    
    [self uploadDeletes:@[]
                uploads:@[ observation ]];
}

- (IBAction)meTapped:(id)sender {
    if (self.isSyncing) {
        [self stopSyncPressed];
    } else {
        NSMutableArray *recordsToDelete = [NSMutableArray array];
        
        for (NSString *modelName in @[ @"Observation", @"ObservationPhoto", @"ObservationFieldValue", @"ProjectObservation" ]) {
            for (ExploreDeletedRecord *dr in [ExploreDeletedRecord needingSyncForModelName:modelName]) {
                [recordsToDelete addObject:dr];
            }
        }
        
        NSArray *recordsToUpload = [ExploreObservationRealm needingUpload];
        if (recordsToDelete.count > 0 || recordsToUpload.count > 0) {
            [self sync:nil];
        } else {
            NSString *title = NSLocalizedString(@"Change your profile photo?", nil);
            // update profile photo
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                           message:@" "
                                                                    preferredStyle:UIAlertControllerStyleActionSheet];
            
            INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
            ExploreUserRealm *me = [appDelegate.loginController meUserLocal];
            if (me.userIcon) {
                [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Remove my profile photo", nil)
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * _Nonnull action) {
                    [self deleteProfilePhoto];
                }]];            	
            }
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Choose from library", nil)
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * _Nonnull action) {
                [self newProfilePhoto:UIImagePickerControllerSourceTypeSavedPhotosAlbum];
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Take a photo", nil)
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * _Nonnull action) {
                [self newProfilePhoto:UIImagePickerControllerSourceTypeCamera];
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            UIButton *btn = (UIButton *)sender;
            
            CGRect rect = [self.view convertRect:btn.frame fromView:btn.superview];
            alert.popoverPresentationController.sourceView = btn;
            alert.popoverPresentationController.sourceRect = rect;
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
}

- (void)deleteProfilePhoto {
    if (![[INatReachability sharedClient] isNetworkReachable]) {
        return;
    }
    
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    ExploreUserRealm *me = [appDelegate.loginController meUserLocal];
    if (me) {
        [[Analytics sharedClient] event:kAnalyticsEventProfilePhotoRemoved];
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.removeFromSuperViewOnHide = YES;
        hud.dimBackground = YES;
        hud.labelText = NSLocalizedString(@"Removing...", nil);
        
        __weak typeof(self) weakSelf = self;
        [self.peopleApi removeProfilePhotoForUserId:me.userId handler:^(NSArray *results, NSInteger count, NSError *error) {
            [hud hide:YES];
            if (error) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Delete Error", nil)
                                                                               message:error.localizedDescription
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                          style:UIAlertActionStyleDefault
                                                        handler:nil]];
                [weakSelf presentViewController:alert animated:YES completion:nil];
            } else {
                // dirty the me user to force re-fetching
                INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
                [appDelegate.loginController dirtyLocalMeUser];

                [weakSelf loadUserForHeader];
            }
        }];
    }
}

- (void)newProfilePhoto:(UIImagePickerControllerSourceType)sourceType {
    if (![UIImagePickerController isSourceTypeAvailable:sourceType]) {
        return;
    }
    
    if (![[INatReachability sharedClient] isNetworkReachable]) {
        return;
    }
    
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = sourceType;
    picker.allowsEditing = YES;
    picker.delegate = self;
    [self.tabBarController presentViewController:picker animated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [self dismissViewControllerAnimated:YES completion:nil];
    
    UIImage *image = [info valueForKey:UIImagePickerControllerEditedImage];
    
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    ExploreUserRealm *me = [appDelegate.loginController meUserLocal];
    if (me) {
        BOOL alreadyHadPhoto = me.userIcon != nil;
        [[Analytics sharedClient] event:kAnalyticsEventProfilePhotoChanged
                         withProperties:@{ @"AlreadyHadPhoto": alreadyHadPhoto ? @"Yes" : @"No" }];
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.removeFromSuperViewOnHide = YES;
        hud.dimBackground = YES;
        hud.labelText = NSLocalizedString(@"Uploading...", nil);
        
        __weak typeof(self) weakSelf = self;
        [self.peopleApi uploadProfilePhoto:image forUserId:me.userId handler:^(NSArray *results, NSInteger count, NSError *error) {
            [hud hide:YES];
            if (error) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Upload Error", nil)
                                                                               message:error.localizedDescription
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                          style:UIAlertActionStyleDefault
                                                        handler:nil]];
                [weakSelf presentViewController:alert animated:YES completion:nil];
            } else {
                // dirty the me user to force re-fetching
                INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
                [appDelegate.loginController dirtyLocalMeUser];
                
                [weakSelf loadUserForHeader];	
            }
        }];
        
    }
}

- (IBAction)sync:(id)sender {
    
    if (self.isSyncing) {
        [self stopSyncPressed];
        return;
    }
    
    NSMutableArray *recordsToDelete = [NSMutableArray array];
    for (NSString *modelName in @[ @"Observation", @"ObservationPhoto", @"ObservationFieldValue", @"ProjectObservation" ]) {
        for (ExploreDeletedRecord *dr in [ExploreDeletedRecord needingSyncForModelName:modelName]) {
            [recordsToDelete addObject:dr];
        }
    }
    
    NSArray *recordsToUpload = [ExploreObservationRealm needingUpload];
    
    [[Analytics sharedClient] event:kAnalyticsEventSyncObservation
                     withProperties:@{
                         @"Via": @"Manual Full Upload",
                         @"numDeletes": @(recordsToDelete.count),
                         @"numUploads": @(recordsToUpload.count),
                     }];
    
    
    [self uploadDeletes:recordsToDelete
                uploads:recordsToUpload];
}

- (void)uploadDeletes:(NSArray *)recordsToDelete uploads:(NSArray *)observationsToUpload {
    
    if (self.isSyncing) {
        return;
    }
    
    if (![[INatReachability sharedClient] isNetworkReachable]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Internet connection required", nil)
                                                                       message:NSLocalizedString(@"You must be connected to the Internet to upload to iNaturalist.org", nil)
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        return;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:INatTokenPrefKey]) {
        [self presentSignupSplashWithReason:NSLocalizedString(@"You must be logged in to upload.", @"This is an explanation for why the upload button triggers a login prompt.")];
        return;
    }
    
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    UploadManager *uploader = appDelegate.loginController.uploadManager;
    
    [uploader syncDeletedRecords:recordsToDelete
          thenUploadObservations:observationsToUpload];
}

- (void)stopSyncPressed {
    [[Analytics sharedClient] event:kAnalyticsEventSyncStopped
                     withProperties:@{
                         @"Via": @"Stop Upload Button",
                     }];
    
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    UploadManager *uploader = appDelegate.loginController.uploadManager;
    [uploader cancelSyncsAndUploads];
}

- (void)syncStopped
{
    // allow sleep
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    
    // stop any persistent upload animations
    [self.meHeader stopAnimatingUpload];
    
    // reload tableview
    [[self tableView] reloadData];
    
}

- (BOOL)isSyncing {
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    return appDelegate.loginController.uploadManager.state != UploadManagerStateIdle;
}

/**
 If sync is pending, -pullToRefresh should sync rather than refreshData.
 The app will always treat the server as the ultimate source of truth for 
 observations. If sync is pending on a local observation, fetching
 from the server would over-write locally changed values. Avoid that by
 always finishing sync before refresh.
 */
- (void)pullToRefresh {
    [self refreshRequestedNotify:YES];
    [self checkForDeleted];
}

- (void)refreshRequestedNotify:(BOOL)notify {
    
    if (![[INatReachability sharedClient] isNetworkReachable]) {
        if (notify) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Network unavailable", nil)
                                                                           message:NSLocalizedString(@"You must be connected to the Internet to upload to iNaturalist.org", nil)
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
            [self.refreshControl endRefreshing];
        }
        
        return;
    }
    
    
    NSInteger itemsToUpload = [[ExploreObservationRealm needingUpload] count];
    for (NSString *modelName in @[ @"Observation", @"ObservationPhoto", @"ObservationFieldValue", @"ProjectObservation" ]) {
        itemsToUpload += [[ExploreDeletedRecord needingSyncForModelName:modelName] count];
    }
    
    if (itemsToUpload > 0) {
        // no implicit upload
        if (!notify) { return; }
        
        [self.refreshControl endRefreshing];
        [self sync:nil];
    } else {
        [self refreshData];
    }
}

- (void)refreshData {
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([appDelegate.loginController isLoggedIn]) {
        
        ExploreUserRealm *me = [appDelegate.loginController meUserLocal];
        [[Analytics sharedClient] debugLog:@"Network - Refresh 10 recent observations"];
        
        // fetch 10, quickly
        __weak typeof(self)weakSelf = self;
        [[self obsApi] observationsForUserId:me.userId count:10 handler:^(NSArray *results, NSInteger count, NSError *error) {
            
            [weakSelf.refreshControl endRefreshing];
            
            RLMRealm *realm = [RLMRealm defaultRealm];
            [realm beginWriteTransaction];
            for (ExploreObservation *eo in results) {
                id value = [ExploreObservationRealm valueForMantleModel:eo];
                ExploreObservationRealm *obs = [ExploreObservationRealm createOrUpdateInRealm:realm withValue:value];
                [obs setSyncedForSelfAndChildrenAt:[NSDate date]];
            }
            [realm commitWriteTransaction];
        }];
        
        
        [[Analytics sharedClient] debugLog:@"Network - Refresh 200 recent observations"];
        // fetch 200 as well
        [[self obsApi] observationsForUserId:me.userId count:200 handler:^(NSArray *results, NSInteger count, NSError *error) {
            
            [weakSelf.refreshControl endRefreshing];
            
            RLMRealm *realm = [RLMRealm defaultRealm];
            [realm beginWriteTransaction];
            for (ExploreObservation *eo in results) {
                id value = [ExploreObservationRealm valueForMantleModel:eo];
                ExploreObservationRealm *obs = [ExploreObservationRealm createOrUpdateInRealm:realm withValue:value];
                [obs setSyncedForSelfAndChildrenAt:[NSDate date]];
            }
            [realm commitWriteTransaction];
            
            [weakSelf checkNewActivity];
        }];
        
        [self loadUserForHeader];
        self.lastRefreshAt = [NSDate date];
    }
}

- (void)checkForDeleted {
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([appDelegate.loginController isLoggedIn]) {
        NSDate *lastSyncDate = [[NSUserDefaults standardUserDefaults] objectForKey:INatLastDeletedSync];
        if (!lastSyncDate) {
            lastSyncDate = [NSDate distantPast];
        } else {
            // move last sync date back by a day
            [lastSyncDate dateByAddingTimeInterval:-(60*60*24)];
        }
        
        [[self obsApi] fetchDeletedObservationsSinceDate:lastSyncDate handler:^(NSArray *results, NSInteger count, NSError *error) {
            // do nothing if we error here
            if (!error) {
                for (NSNumber *obsIdToDelete in results) {
                    RLMResults *observationsToDelete = [ExploreObservationRealm objectsWhere:@"observationId == %@", obsIdToDelete];
                    for (ExploreObservationRealm *o in observationsToDelete) {
                        // already gone on the server, so just delete locally
                        [ExploreObservationRealm deleteWithoutSync:o];
                    }
                }
                
                
                [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:INatLastDeletedSync];
                [[NSUserDefaults standardUserDefaults] synchronize];
            }
        }];
    }
}

- (void)checkNewActivity {
    if ([[INatReachability sharedClient] isNetworkReachable]) {
        [[Analytics sharedClient] debugLog:@"Network - Get My Updates Activity"];
        [[self obsApi] updatesWithHandler:^(NSArray *results, NSInteger count, NSError *error) {
            if (error) {
                return;
            }
            
            RLMRealm *realm = [RLMRealm defaultRealm];
            [realm beginWriteTransaction];
            for (ExploreUpdate *eu in results) {
                ExploreUpdateRealm *eur = [[ExploreUpdateRealm alloc] initWithMantleModel:eu];
                [realm addOrUpdateObject:eur];
            }
            [realm commitWriteTransaction];
        }];
    }
}

- (BOOL)autoLaunchNewFeatures
{
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    NSString *versionString = [info objectForKey:@"CFBundleShortVersionString"];
    NSString *lastVersionString = [settings objectForKey:@"lastVersion"];
    if ([lastVersionString isEqualToString:versionString]) {
        return NO;
    }
    [[NSUserDefaults standardUserDefaults] setValue:versionString forKey:@"lastVersion"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    CustomIOSAlertView *alertView = [[CustomIOSAlertView alloc] init];
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (UIInterfaceOrientationIsLandscape(interfaceOrientation)) {
        CGFloat tmp = screenWidth;
        screenWidth = screenHeight;
        screenHeight = tmp;
    }
    CGFloat widthFraction = 0.9;
    CGFloat heightFraction = 0.6;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        widthFraction = 0.7;
        heightFraction = 0.4;
    }
    UIView *popup = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth*widthFraction, screenHeight*heightFraction)];
    popup.backgroundColor = [UIColor clearColor];
    UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectMake(10,10, popup.bounds.size.width-20, popup.bounds.size.height-20)];
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    NSString *changesFilePath = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"changes.%@", language]
                                                                ofType:@"html"
                                                           inDirectory:@"www"];
    if (!changesFilePath) {
        // if we don't have changes files for this user's preferred language,
        // default to english
        changesFilePath = [[NSBundle mainBundle] pathForResource:@"changes.en"
                                                          ofType:@"html"
                                                     inDirectory:@"www"];
    }
    
    // be defensive
    if (changesFilePath) {
        NSURL *url = [NSURL fileURLWithPath:changesFilePath];
        [webView loadRequest:[NSURLRequest requestWithURL:url]];
        [popup addSubview:webView];
        [alertView setContainerView:popup];
        [alertView setButtonTitles:[NSMutableArray arrayWithObjects:NSLocalizedString(@"OK",nil), nil]];
        [alertView setOnButtonTouchUpInside:^(CustomIOSAlertView *alertView, int buttonIndex) {
            [alertView close];
        }];
        [alertView setUseMotionEffects:true];
        [alertView show];
        [settings setObject:versionString forKey:@"lastVersion"];
        [settings synchronize];
        
        return YES;
    } else {
        return NO;
    }
    
}

- (void)clickedActivity:(id)sender event:(UIEvent *)event {
    CGPoint currentTouchPosition = [event.allTouches.anyObject locationInView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:currentTouchPosition];
    id <ObservationVisualization> o = [self.myObservations objectAtIndex:indexPath.item];
    // fake a selection
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    // transition to obs detail
    [self performSegueWithIdentifier:@"obsDetailV2" sender:o];
    return;
}

- (void)showError:(NSString *)errorMessage{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                                   message:errorMessage
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // side effect in fetch sections - show or hide background/default view
    tableView.backgroundView.hidden = self.myObservations.count != 0;
    return 1;
}

# pragma mark TableViewController methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.myObservations.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ExploreObservationRealm *o;
    @try {
        o = [self.myObservations objectAtIndex:indexPath.item];
    } @catch (NSException *exception) {
        // return a cell but don't configure it
        return [tableView dequeueReusableCellWithIdentifier:@"ObservationNormalCell"];
    }
    
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    UploadManager *uploader = appDelegate.loginController.uploadManager;
    
    if (o.validationErrorMsg && o.validationErrorMsg.length > 0 && uploader.state == UploadManagerStateIdle) {
        // only show validation error status if this obs has a validation error, and it's not being retried
        ObservationViewErrorCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ObservationErrorCell"];
        [self configureErrorCell:cell forIndexPath:indexPath];
        return cell;
    } else if (o.needsUpload || o.childrenNeedingUpload.count > 0) {
        if ([self.uploadProgress valueForKey:o.uuid]) {
            // actively uploading this observation
            ObservationViewUploadingCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ObservationUploadingCell"];
            [self configureUploadingCell:cell forIndexPath:indexPath];
            return cell;
        } else {
            // waiting upload, not actively uploading this observation
            ObservationViewWaitingUploadCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ObservationWaitingUploadCell"];
            [self configureWaitingUploadCell:cell forIndexPath:indexPath];
            return cell;
        }
    } else {
        ObservationViewNormalCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ObservationNormalCell"];
        [self configureNormalCell:cell forIndexPath:indexPath];
        return cell;
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 54.0f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    UploadManager *uploader = appDelegate.loginController.uploadManager;
    id <Uploadable, ObservationVisualization> o = [self.myObservations objectAtIndex:indexPath.item];
    
    if (uploader.state != UploadManagerStateIdle && (o.needsUpload || o.childrenNeedingUpload.count > 0)) {
        return;
    } else {
        [self performSegueWithIdentifier:@"obsDetailV2" sender:o];
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 100;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.loggedIn) {
        return self.meHeader;
    } else {
        return self.anonHeader;
    }
}

#pragma mark - TableViewCell helpers

- (void)configureObservationCell:(ObservationViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    ExploreObservationRealm *o = [self.myObservations objectAtIndex:indexPath.item];
    
    if (o.observationPhotos.count > 0) {
        ExploreObservationPhotoRealm *op = [o.sortedObservationPhotos firstObject];
        cell.observationImage.image = [[ImageStore sharedImageStore] find:op.photoKey forSize:ImageStoreSquareSize];
        if (cell.observationImage.image == nil) {
            [cell.observationImage sd_setImageWithURL:[op squarePhotoUrl]];
        }        
    } else {
        cell.observationImage.image = [[ImageStore sharedImageStore] iconicTaxonImageForName:o.iconicTaxonName];
    }
    
    cell.observationImage.layer.cornerRadius = 1.0f;
    cell.observationImage.layer.borderWidth = 1.0f;
    cell.observationImage.layer.borderColor = [UIColor colorWithHexString:@"#C8C7CC"].CGColor;
    cell.observationImage.clipsToBounds = YES;
    
    if ([o taxon]) {
        [cell.titleLabel setText:o.taxon.displayFirstName];
        if (o.taxon.displayFirstNameIsItalicized) {
            cell.titleLabel.font = [UIFont italicSystemFontOfSize:cell.titleLabel.font.pointSize];
        }
    } else if (o.speciesGuess && o.speciesGuess.length > 0) {
        [cell.titleLabel setText:o.speciesGuess];
    } else {
        [cell.titleLabel setText:NSLocalizedString(@"Unknown", @"unknown taxon")];
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleGray;
}

- (void)configureErrorCell:(ObservationViewErrorCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    [self configureObservationCell:cell forIndexPath:indexPath];
    
    id <ObservationVisualization> o = [self.myObservations objectAtIndex:indexPath.item];
    
    cell.dateLabel.text = [o.observedOn inat_shortRelativeDateString];
    cell.subtitleLabel.text = NSLocalizedString(@"Needs Your Attention", @"subtitle for an observation that failed validation.");
}

- (void)configureUploadingCell:(ObservationViewUploadingCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    [self configureObservationCell:cell forIndexPath:indexPath];
    
    cell.subtitleLabel.text = NSLocalizedString(@"Uploading...", @"subtitle for observation while it's uploading.");
    
    id <ObservationVisualization> o = [self.myObservations objectAtIndex:indexPath.item];
    
    if (o.uuid) {
        float progress = [self.uploadProgress[o.uuid] floatValue];
        [cell.progressBar setProgress:progress];
    }
    
    cell.dateLabel.text = [o.observedOn inat_shortRelativeDateString];

    cell.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)configureWaitingUploadCell:(ObservationViewWaitingUploadCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    [self configureObservationCell:cell forIndexPath:indexPath];
    
    cell.subtitleLabel.text = NSLocalizedString(@"Waiting to upload...", @"Subtitle for observation when waiting to upload.");
    [cell.uploadButton addTarget:self
                          action:@selector(uploadOneObservation:)
                forControlEvents:UIControlEventTouchUpInside];
    
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    UploadManager *uploader = appDelegate.loginController.uploadManager;
    if (uploader.state == UploadManagerStateIdle) {
        // waiting upload, with uploads not happening
        cell.uploadButton.enabled = YES;
        cell.backgroundColor = [[UIColor inatTint] colorWithAlphaComponent:0.2f];
        cell.subtitleLabel.textColor = [UIColor colorWithHexString:@"#787878"];
        cell.titleLabel.textColor = [UIColor blackColor];
        cell.observationImage.alpha = 1.0f;
    } else {
        // waiting upload, with uploads happening
        cell.uploadButton.enabled = NO;
        cell.backgroundColor = [UIColor colorWithHexString:@"#eaeaea"];
        cell.titleLabel.textColor = [UIColor colorWithHexString:@"#969696"];
        cell.subtitleLabel.textColor = [UIColor colorWithHexString:@"#969696"];
        cell.observationImage.alpha = 0.5f;
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)configureNormalCell:(ObservationViewNormalCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    [self configureObservationCell:cell forIndexPath:indexPath];
    
    ExploreObservationRealm *o = [self.myObservations objectAtIndex:indexPath.item];
    
    if (o.placeGuess && o.placeGuess.length > 0) {
        cell.subtitleLabel.text = o.placeGuess;
    } else if (CLLocationCoordinate2DIsValid(o.location)) {
        cell.subtitleLabel.text = [NSString stringWithFormat:@"%ld, %ld", (long)o.location.latitude, (long)o.location.longitude];
    } else {
        cell.subtitleLabel.text = NSLocalizedString(@"Somewhere...",nil);
    }
    
    if (o.hasUnviewedActivityBool) {
        [cell.activityButton setBackgroundImage:[UIImage imageNamed:@"08-chat-red"] forState:UIControlStateNormal];
    } else {
        [cell.activityButton setBackgroundImage:[UIImage imageNamed:@"08-chat"] forState:UIControlStateNormal];
    }
    
    [cell.activityButton setTitle:[NSString stringWithFormat:@"%ld", (long)o.activityCount] forState:UIControlStateNormal];
    
    if (o.activityCount > 0) {
        cell.activityButton.hidden = NO;
        cell.interactiveActivityButton.hidden = NO;
    } else {
        cell.activityButton.hidden = YES;
        cell.interactiveActivityButton.hidden = YES;
    }
    
    [cell.interactiveActivityButton addTarget:self
                                       action:@selector(clickedActivity:event:)
                             forControlEvents:UIControlEventTouchUpInside];
    
    if (o.timeObserved) {
        cell.dateLabel.text = [o.timeObserved inat_shortRelativeDateString];
    } else {
        cell.dateLabel.text = nil;
    }
}


#pragma mark - Header helpers

- (void)configureHeaderForLoggedInUser {
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([appDelegate.loginController isLoggedIn]) {
        // initially configure header for the cached user...
        ExploreUserRealm *me = [appDelegate.loginController meUserLocal];
        self.navigationItem.title = me.login;
        [self configureHeaderView:self.meHeader forUser:me];
        
        // and try to fetch the user from the server just in case
        __weak typeof(self)weakSelf = self;
        [appDelegate.loginController meUserRemoteCompletion:^(ExploreUserRealm *me) {
            if (me) {
                weakSelf.navigationItem.title = me.login;
                [weakSelf configureHeaderView:self.meHeader forUser:me];
            }
        }];
    } else {
        self.navigationItem.title = NSLocalizedString(@"Me", @"Placeholder text for not logged title on me tab.");
    }
}

- (void)configureHeaderForCancelled:(MeHeaderView *)view {
    view.obsCountLabel.text = NSLocalizedString(@"Cancelling...", @"Title of me header while cancellling an upload session.");
    [view startAnimatingUpload];
}

- (void)configureHeaderForActiveUploading:(MeHeaderView *)view {
    [view.iconButton cancelImageDownloadTaskForState:UIControlStateNormal];
    [view.iconButton setBackgroundImage:nil forState:UIControlStateNormal];
    [view.iconButton setTintColor:[UIColor whiteColor]];
    view.iconButton.backgroundColor = [UIColor inatTint];
    
    // allow cancel
    FAKIcon *stopIcon = [FAKIonIcons iosCloseOutlineIconWithSize:50];
    [view.iconButton setAttributedTitle:stopIcon.attributedString
                               forState:UIControlStateNormal];
    view.iconButton.enabled = YES;
    view.iconButton.accessibilityLabel = NSLocalizedString(@"Stop Uploading",
                                                           @"accessibility label for stop uploading button");
    view.obsCountLabel.text = NSLocalizedString(@"Syncing...", @"Title of me header when syncing.");
    
    [view startAnimatingUpload];
}

- (void)configureHeaderView:(MeHeaderView *)view forUser:(id <UserVisualization>)user {
    NSInteger needingUploadCount = [[ExploreObservationRealm needingUpload] count];
    
    NSInteger needingDeleteCount = 0;
    for (NSString *modelName in @[ @"Observation", @"ObservationPhoto", @"ObservationFieldValue", @"ProjectObservation" ]) {
        needingDeleteCount += [[ExploreDeletedRecord needingSyncForModelName:modelName] count];
    }
    
    if (needingUploadCount > 0 || needingDeleteCount > 0) {
        
        INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
        UploadManager *uploadManager = appDelegate.loginController.uploadManager;
        
        if (uploadManager.state == UploadManagerStateUploading) {
            [self configureHeaderForActiveUploading:view];
        } else if (uploadManager.state == UploadManagerStateCancelling) {
            [self configureHeaderForCancelled:view];
        } else {
            // cancel any existing upload animations
            [view stopAnimatingUpload];
            
            NSString *uploadButtonTitleText = NSLocalizedString(@"Upload", @"Title for upload button.");
            
            FAKIcon *uploadIcon = [FAKIonIcons iosCloudUploadIconWithSize:46];
            NSMutableAttributedString *uploadIconString = [[NSMutableAttributedString alloc] initWithAttributedString:uploadIcon.attributedString];
            // explicit linebreak because uilabel doesn't seem to be able to calculate number of lines required with a FAK glyph
            NSString *uploadButtonSecondLine = [NSString stringWithFormat:@"\n%@", uploadButtonTitleText];
            [uploadIconString appendAttributedString:[[NSAttributedString alloc] initWithString:uploadButtonSecondLine
                                                                                     attributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:11] }]];
            
            // set a max line height on the "Upload" text line. required because the first line of the label is a 50pt glyph
            NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
            paragraphStyle.lineSpacing = 0;
            paragraphStyle.maximumLineHeight = 11;
            paragraphStyle.alignment = NSTextAlignmentCenter;
            [uploadIconString addAttribute:NSParagraphStyleAttributeName
                                     value:paragraphStyle
                                     range:NSMakeRange(2, uploadIconString.length - 2)];
            
            // image seems to override title text, so clear it
            [view.iconButton cancelImageDownloadTaskForState:UIControlStateNormal];
            [view.iconButton setBackgroundImage:nil forState:UIControlStateNormal];
            view.iconButton.accessibilityLabel = NSLocalizedString(@"Upload",
                                                                   @"accessibility labelf for upload button");
            
            view.iconButton.backgroundColor = [UIColor inatTint];
            view.iconButton.tintColor = [UIColor whiteColor];
            [view.iconButton setAttributedTitle:uploadIconString
                                       forState:UIControlStateNormal];
            
            // the upload icon is one line of attributed text
            view.iconButton.titleLabel.numberOfLines = 2;
            view.iconButton.titleLabel.textAlignment = NSTextAlignmentCenter;
            
            // allow interaction with the upload button
            view.iconButton.enabled = YES;
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                // only animate the upload button if it's still an upload button
                NSString *uploadButtonCurrentTitle = [[view.iconButton attributedTitleForState:UIControlStateNormal] string];
                if (!uploadButtonCurrentTitle || [uploadButtonCurrentTitle rangeOfString:uploadButtonTitleText].location == NSNotFound) {
                    return;
                }
                
                [UIView animateWithDuration:0.2f
                                      delay:0.0f
                                    options:UIViewAnimationOptionAllowUserInteraction
                                 animations:^{
                    view.iconButton.transform = CGAffineTransformMakeScale(1.1f, 1.1f);
                } completion:^(BOOL finished) {
                    [UIView animateWithDuration:0.2f
                                          delay:0.0f
                                        options:UIViewAnimationOptionAllowUserInteraction
                                     animations:^{
                        view.iconButton.transform = CGAffineTransformMakeScale(0.95f, 0.95f);
                    } completion:^(BOOL finished) {
                        [UIView animateWithDuration:0.2f
                                              delay:0.0f
                                            options:UIViewAnimationOptionAllowUserInteraction
                                         animations:^{
                            view.iconButton.transform = CGAffineTransformIdentity;
                        }
                                         completion:nil];
                    }];
                }];
            });
            
            if (needingUploadCount > 0) {
                NSString *baseUploadCountStr;
                if (needingUploadCount == 1) {
                    baseUploadCountStr = NSLocalizedString(@"%d Observation To Upload",
                                                           @"Count of observations to upload, singular.");
                } else {
                    baseUploadCountStr = NSLocalizedString(@"%d Observations To Upload",
                                                           @"Count of observations to upload, plural.");
                }
                view.obsCountLabel.text = [NSString stringWithFormat:baseUploadCountStr, needingUploadCount];
            } else if (needingDeleteCount > 0) {
                view.obsCountLabel.text = NSLocalizedString(@"Deletes To Sync",
                                                            @"Deletes pending sync.");
            }
        }
        
        
        
    } else {
        [view.iconButton setAttributedTitle:nil forState:UIControlStateNormal];
        view.iconButton.backgroundColor = [UIColor clearColor];
        view.iconButton.enabled = YES;
        view.iconButton.accessibilityLabel = NSLocalizedString(@"Set Profile Photo",
                                                               @"accessibility label for choose profile photo button");
        
        // icon
        if (user.userIconMedium) {
            [view.iconButton setTitle:nil forState:UIControlStateNormal];
            [view.iconButton setBackgroundImageForState:UIControlStateNormal
                                                withURL:user.userIconMedium];
        } else if (user.userIcon) {
            [view.iconButton setTitle:nil forState:UIControlStateNormal];
            [view.iconButton setBackgroundImageForState:UIControlStateNormal
                                                withURL:user.userIcon];
        } else {
            FAKIcon *person = [FAKIonIcons iosPersonIconWithSize:80.0f];
            [person addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor]];
            UIImage *personImage = [[person imageWithSize:CGSizeMake(80,80)] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
            
            [view.iconButton setTitle:nil forState:UIControlStateNormal];
            [view.iconButton setBackgroundImage:personImage
                                       forState:UIControlStateNormal];
        }
        
        // observation count
        NSInteger observationCount = MAX(user.observationsCount, [[ExploreObservationRealm allObjects] count]);
        if (observationCount > 0) {
            NSString *baseObsCountStr;
            if (observationCount == 1) {
                baseObsCountStr = NSLocalizedString(@"%d Observation", @"Count of observations by this user, singular.");
            } else {
                baseObsCountStr = NSLocalizedString(@"%d Observations", @"Count of observations by this user, plural.");
            }
            view.obsCountLabel.text = [NSString stringWithFormat:baseObsCountStr, observationCount];
        } else {
            view.obsCountLabel.text = NSLocalizedString(@"No Observations", @"Header observation count title when there are none.");
        }
    }
}

- (void)loadUserForHeader {
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([appDelegate.loginController isLoggedIn]) {
        
        ExploreUserRealm *me = [appDelegate.loginController meUserLocal];
        self.navigationItem.title = me.login;
        
        if ([[INatReachability sharedClient] isNetworkReachable]) {
            __weak typeof(self)weakSelf = self;
            [appDelegate.loginController meUserRemoteCompletion:^(ExploreUserRealm *me) {
                [weakSelf.tableView reloadData];
            }];
        }
    } else {
        self.navigationItem.title = NSLocalizedString(@"Me", @"Placeholder text for not logged title on me tab.");
    }
}

# pragma mark memory management
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - NSNotificationCenter

- (void)userSignedIn {
    // this notification can come in off the main thread
    // update the ui for the logged in user on the main thread
    dispatch_async(dispatch_get_main_queue(), ^{
        // configure the header for this new user
        [self configureHeaderForLoggedInUser];

        // update the UI
        [self.tableView reloadData];
        
        // request the users' observations from iNat
        [self refreshRequestedNotify:YES];
    });
}

- (void)userSignedOut {
    // this notification can come in off the main thread
    // update the ui to reflect the logged out state
    dispatch_async(dispatch_get_main_queue(), ^{
        self.navigationItem.title = NSLocalizedString(@"Me", @"Placeholder text for not logged title on me tab.");
        [self.tableView reloadData];
    });
}


#pragma mark - MFMAilCompose delegate

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)presentMigrationReportEmail:(NSString *)migrationReport {
    if (![MFMailComposeViewController canSendMail]) {
        return;
    }
    
    if (!migrationReport) {
        return;
    }
    
    MFMailComposeViewController* composeVC = [[MFMailComposeViewController alloc] init];
    composeVC.mailComposeDelegate = self;
    
    NSArray *toAddresses = @[ @"help@inaturalist.org" ];
    
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    NSString *versionText = [NSString stringWithFormat:NSLocalizedString(@"%@, build %@",nil),
                             [info objectForKey:@"CFBundleShortVersionString"] ?: @"unknown version",
                             [info objectForKey:@"CFBundleVersion"] ?: @"unknown version"];
    
    NSString *emailTitle = [NSString stringWithFormat:@"iNaturalist MigrationReport - version %@", versionText];
    
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([appDelegate.loginController isLoggedIn]) {
        ExploreUserRealm *me = [appDelegate.loginController meUserLocal];
        emailTitle = [emailTitle stringByAppendingString:[NSString stringWithFormat:@" user id: %ld,", (long)me.userId]];
        emailTitle = [emailTitle stringByAppendingString:[NSString stringWithFormat:@" username: %@", me.login]];
    } else {
        emailTitle = [emailTitle stringByAppendingString:@" user not logged in"];
    }
    
    // Configure the fields of the interface.
    [composeVC setToRecipients:toAddresses];
    [composeVC setSubject:emailTitle];
    
    NSData *reportData = [migrationReport dataUsingEncoding:NSUTF8StringEncoding];
    [composeVC addAttachmentData:reportData
                        mimeType:@"text/plain"
                        fileName:@"migrationReport.log"];
    
    // Present the view controller modally.
    [self presentViewController:composeVC animated:YES completion:nil];
}

#pragma mark - View lifecycle

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.navigationController.tabBarItem.image = ({
            FAKIcon *meInactive = [FAKIonIcons iosPersonIconWithSize:40];
            [meInactive addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor]];
            [[meInactive imageWithSize:CGSizeMake(34, 45)] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        });
        
        self.navigationController.tabBarItem.selectedImage = ({
            FAKIcon *meActive = [FAKIonIcons iosPersonIconWithSize:40];
            [meActive addAttribute:NSForegroundColorAttributeName value:[UIColor inatTint]];
            [[meActive imageWithSize:CGSizeMake(34, 45)] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        });
        
        self.navigationController.tabBarItem.title = NSLocalizedString(@"Me", nil);
        
        self.uploadProgress = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    NSLog(@"in obs did load, all obs in realm is %ld", [[ExploreObservationRealm allObjectsInRealm:realm] count]);

    
    RLMSortDescriptor *createdAtSort = [RLMSortDescriptor sortDescriptorWithKeyPath:@"timeCreated" ascending:FALSE];
    self.myObservations = [[ExploreObservationRealm myObservations] sortedResultsUsingDescriptors:@[ createdAtSort ]];
    
    __weak typeof(self)weakSelf = self;
    self.myObsNoteToken = [self.myObservations addNotificationBlock:^(RLMResults * _Nullable results, RLMCollectionChange * _Nullable change, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf configureHeaderForLoggedInUser];
            [weakSelf.tableView reloadData];
        });
    }];
    
    self.myUpdates = [ExploreUpdateRealm allObjects];
    self.myUpdatesNoteToken = [self.myUpdates addNotificationBlock:^(RLMResults * _Nullable results, RLMCollectionChange * _Nullable change, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.tableView reloadData];
        });
    }];
    
    self.meHeader = [[[NSBundle mainBundle] loadNibNamed:@"MeHeaderView"
                                                   owner:nil
                                                 options:nil] firstObject];
    
    self.anonHeader = [[[NSBundle mainBundle] loadNibNamed:@"AnonHeaderView"
                                                     owner:nil
                                                   options:nil] firstObject];
    
    [self.meHeader.iconButton addTarget:self
                                 action:@selector(meTapped:)
                       forControlEvents:UIControlEventTouchUpInside];
    
    [self configureHeaderForLoggedInUser];
    
    self.tableView.backgroundView = ({
        UIView *view = [UIView new];
        
        UIView *container = [UIView new];
        container.translatesAutoresizingMaskIntoConstraints = NO;
        UIImageView *iv = [UIImageView new];
        iv.translatesAutoresizingMaskIntoConstraints = NO;
        iv.contentMode = UIViewContentModeCenter;
        iv.image = ({
            UIImage *binocs = [[UIImage imageNamed:@"binocs"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            UIGraphicsBeginImageContextWithOptions(binocs.size, NO, binocs.scale);
            [[UIColor lightGrayColor] set];
            [binocs drawInRect:CGRectMake(0, 0, binocs.size.width, binocs.size.height)];
            binocs = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            binocs;
        });
        [container addSubview:iv];
        
        UILabel *label = [UILabel new];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        label.numberOfLines = 0;
        label.textAlignment = NSTextAlignmentCenter;
        
        label.attributedText = ({
            NSString *emptyTitle = NSLocalizedString(@"Looks like you have no observations.", @"Notice to display to the user on the Me tab when they have no observations");
            NSDictionary *attrs = @{
                NSForegroundColorAttributeName: [UIColor grayColor],
                NSFontAttributeName: [UIFont systemFontOfSize:14.0f],
            };
            [[NSAttributedString alloc] initWithString:emptyTitle
                                            attributes:attrs];
        });
        [container addSubview:label];
        
        NSDictionary *views = @{
            @"iv": iv,
            @"label": label,
            @"container": container,
        };
        
        [container addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-20-[iv]-20-|"
                                                                          options:0
                                                                          metrics:0
                                                                            views:views]];
        [container addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-20-[label]-20-|"
                                                                          options:0
                                                                          metrics:0
                                                                            views:views]];
        [container addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[iv]-[label]|"
                                                                          options:0
                                                                          metrics:0
                                                                            views:views]];
        [view addConstraint:[NSLayoutConstraint constraintWithItem:container
                                                         attribute:NSLayoutAttributeCenterX
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:view
                                                         attribute:NSLayoutAttributeCenterX
                                                        multiplier:1.0
                                                          constant:0.0]];
        [view addConstraint:[NSLayoutConstraint constraintWithItem:container
                                                         attribute:NSLayoutAttributeCenterY
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:view
                                                         attribute:NSLayoutAttributeCenterY
                                                        multiplier:1.0
                                                          constant:0.0]];
        
        
        [view addSubview:container];
        
        view;
    });
    
    
    static NSString *FirstSignInKey = @"firstSignInSeen";
    static NSString *SeenV262Key = @"seenVersion262";
    static NSString *SeenV27Key = @"seenVersion27";
    static NSString *RanMigrationToRealmKey = @"ranMigrationToRealmKey7";
    static NSString *SeenV32Key = @"seenVersion32";     // added some common name prefs
    
    // re-using 'firstSignInSeen' BOOL, which used to be set during the initial launch
    // when the user saw the login prompt for the first time.
    if (![[NSUserDefaults standardUserDefaults] boolForKey:FirstSignInKey]) {
        // completely new users default to autocomplete on
        [[NSUserDefaults standardUserDefaults] setBool:YES
                                                forKey:kINatAutocompleteNamesPrefKey];
        
        // completely new users default to autoupload on
        [[NSUserDefaults standardUserDefaults] setBool:YES
                                                forKey:kInatAutouploadPrefKey];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES
                                                forKey:FirstSignInKey];
        [[NSUserDefaults standardUserDefaults] setBool:YES
                                                forKey:SeenV262Key];
        
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    // new settings as of 2.6.2, for existing users
    if (![[NSUserDefaults standardUserDefaults] boolForKey:SeenV262Key]) {
        // existing users default to autoupload off
        [[NSUserDefaults standardUserDefaults] setBool:NO
                                                forKey:kInatAutouploadPrefKey];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES
                                                forKey:SeenV262Key];
        
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [self presentAutouploadAlert];
    }
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:SeenV27Key]) {
        // existing users default to suggestions on
        [[NSUserDefaults standardUserDefaults] setBool:YES
                                                forKey:kINatSuggestionsPrefKey];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES
                                                forKey:SeenV27Key];
        
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:RanMigrationToRealmKey]) {
        __weak typeof(self) weakSelf = self;
        [[self migrationAssistant] migrateObservationsToRealmProgress:^(CGFloat progress) {
            // do nothing for now, no hud
        } finished:^(BOOL success, NSString *migrationReport, NSError *error) {
            if (success) {
                // mark the migration as a success
                [[NSUserDefaults standardUserDefaults] setBool:YES
                                                        forKey:RanMigrationToRealmKey];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                if (!migrationReport) {
                    return;
                }
                NSString *migrationProblemTitle = NSLocalizedString(@"Migration Problem", @"Title for alert when db migration had a problem.");
                NSString *migrationEmailPromptMsg = NSLocalizedString(@"Would you like to share your migration report with help@inaturalist.org for debugging?", @"message for alert when db migration has a problem");
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:migrationProblemTitle
                                                                               message:migrationEmailPromptMsg
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:@"Email help@inaturalist"
                                                          style:UIAlertActionStyleDefault
                                                        handler:^(UIAlertAction * _Nonnull action) {
                    [weakSelf presentMigrationReportEmail:migrationReport];
                }]];
                
                [alert addAction:[UIAlertAction actionWithTitle:@"Ignore"
                                                          style:UIAlertActionStyleCancel
                                                        handler:nil]];
                [weakSelf presentViewController:alert animated:YES completion:nil];
            } else {
                NSString *migrationFailedTitle = NSLocalizedString(@"Migration Failed", @"Title for alert when db migration fails.");
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:migrationFailedTitle
                                                                               message:migrationReport
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                                          style:UIAlertActionStyleDefault
                                                        handler:nil]];
                [weakSelf presentViewController:alert animated:YES completion:nil];
            }
        }];
    }
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:SeenV32Key]) {
        // existing users default to see common names, scientific names second
        // this will be overwritten next time we fetch a user object
        // from iNat.org, but good to start with sensible defaults
        [[NSUserDefaults standardUserDefaults] setBool:YES
                                                forKey:kINatShowCommonNamesPrefKey];
        [[NSUserDefaults standardUserDefaults] setBool:NO
                                                forKey:kINatShowScientificNamesFirstPrefKey];

        [[NSUserDefaults standardUserDefaults] setBool:YES
                                                forKey:SeenV32Key];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userSignedIn)
                                                 name:kUserLoggedInNotificationName
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userSignedOut)
                                                 name:kUserLoggedOutNotificationName
                                               object:nil];

    
    self.navigationItem.leftBarButtonItem = nil;
    FAKIcon *settings = [FAKIonIcons iosGearOutlineIconWithSize:30];
    UIImage *settingsImage = [settings imageWithSize:CGSizeMake(30, 30)];
    settings.iconFontSize = 20;
    UIImage *settingsLandscapeImage = [settings imageWithSize:CGSizeMake(20, 20)];
    
    UIBarButtonItem *settingsBarButton = [[UIBarButtonItem alloc] initWithImage:settingsImage
                                                            landscapeImagePhone:settingsLandscapeImage
                                                                          style:UIBarButtonItemStylePlain
                                                                         target:self
                                                                         action:@selector(settings)];
    settingsBarButton.accessibilityLabel = NSLocalizedString(@"Settings", @"accessibility label for settings button");
    self.navigationItem.rightBarButtonItem = settingsBarButton;
    
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.loginController.uploadManager setDelegate:self];
    
    [self.anonHeader.loginButton addTarget:self
                                    action:@selector(login)
                          forControlEvents:UIControlEventTouchUpInside];
    
    [self.anonHeader.signupButton addTarget:self
                                     action:@selector(signup)
                           forControlEvents:UIControlEventTouchUpInside];
    
}

- (void)login {
    [self presentLoginSplashWithReason:nil];
}

- (void)signup {
    [self presentSignupSplashWithReason:nil];
}

- (void)settings {
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    UIViewController *vc = [storyBoard instantiateViewControllerWithIdentifier:@"Settings"];
    [self.navigationController pushViewController:vc animated:YES];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController setToolbarHidden:YES animated:YES];
    
    self.navigationController.navigationBar.translucent = NO;
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor inatTint];
    
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([appDelegate.loginController isLoggedIn]) {
        RefreshControl *refresh = [[RefreshControl alloc] init];
        refresh.backgroundColor = [UIColor inatDarkGray];
        refresh.tintColor = [UIColor whiteColor];
        refresh.attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Pull to Refresh", nil)
                                                                  attributes:@{ NSForegroundColorAttributeName: [UIColor whiteColor] }];
        [refresh addTarget:self action:@selector(pullToRefresh) forControlEvents:UIControlEventValueChanged];
        self.refreshControl = refresh;
    } else {
        self.refreshControl = nil;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // automatically sync if there's network and we haven't synced in the last hour
    CGFloat minutes = 60,
    seconds = minutes * 60;
    
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([appDelegate.loginController isLoggedIn] &&
        [[INatReachability sharedClient] isNetworkReachable] &&
        (!self.lastRefreshAt || [self.lastRefreshAt timeIntervalSinceNow] < -1*seconds)) {
        [self refreshRequestedNotify:NO];
        [self checkForDeleted];
        [self checkNewActivity];
    }
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];    
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIDeviceOrientationPortrait);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"obsDetailV2"]) {
        ObsDetailV2ViewController *ovc = [segue destinationViewController];
        ovc.observation = (ExploreObservationRealm *)sender;
        [[Analytics sharedClient] event:kAnalyticsEventNavigateObservationDetail
                         withProperties:@{ @"via": @"Me Tab" }];
    }
}

- (void)dealloc {
    [self.myObsNoteToken invalidate];
    [self.myUpdatesNoteToken invalidate];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

// TODO: update notification delegate for ObservationVisualization right? or Uploadable?

#pragma mark - Upload Notification Delegate

- (void)uploadSessionFinished {
    // dirty the me user to force re-fetching
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.loginController dirtyLocalMeUser];
    
    // allow any pending upload animations to finish
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [self syncStopped];
        
        // reload the Me user from the server
        [self loadUserForHeader];
    });
    
    UIViewController *topVC = self.navigationController.topViewController;
    if ([topVC isKindOfClass:[ObsDetailV2ViewController class]]) {
        ObsDetailV2ViewController *obsDetail = (ObsDetailV2ViewController *)topVC;
        [obsDetail uploadFinished];
    }
    
    // TODO: clear all upload ids
    
    [[Analytics sharedClient] debugLog:@"Upload - Session Finished"];
    [[Analytics sharedClient] event:kAnalyticsEventSyncStopped
                     withProperties:@{
                         @"Via": @"Upload Complete",
                     }];
}

- (void)uploadSessionCancelledFor:(NSString *)observationUUID {
    [[Analytics sharedClient] debugLog:@"Upload - Upload Cancelled"];
    
    self.meHeader.obsCountLabel.text = NSLocalizedString(@"Cancelling...", @"Title of me header while cancellling an upload session.");
    [self syncStopped];
}

- (void)uploadSessionStarted:(NSString *)observationUUID {
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    self.uploadProgress[observationUUID] = @(0);
    
    [self configureHeaderForLoggedInUser];
    [self.meHeader startAnimatingUpload];
    
    ExploreObservationRealm *o = [ExploreObservationRealm objectForPrimaryKey:observationUUID];
    NSIndexPath *ip = [NSIndexPath indexPathForItem:[self.myObservations indexOfObject:o]
                                          inSection:0];
    if (ip) {
        [self.tableView reloadRowsAtIndexPaths:@[ ip ]
                              withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)uploadSessionSuccessFor:(NSString *)observationUUID {
    [[Analytics sharedClient] debugLog:@"Upload - Success"];
    
    [self configureHeaderForLoggedInUser];
    
    self.uploadProgress[observationUUID] = nil;
    
    ExploreObservationRealm *o = [ExploreObservationRealm objectForPrimaryKey:observationUUID];
    NSIndexPath *ip = [NSIndexPath indexPathForItem:[self.myObservations indexOfObject:o]
                                          inSection:0];
    if (ip) {
        [self.tableView reloadRowsAtIndexPaths:@[ ip ]
                              withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)uploadSessionProgress:(float)progress for:(NSString *)observationUUID {
    self.uploadProgress[observationUUID] = @(progress);
    
    // don't update the UI if this view controller is offscreen
    if (self.presentedViewController) { return; }
    if (self.navigationController.topViewController != self) { return; }
    if (self.tabBarController.selectedViewController != self.navigationController) { return; }
    
    ExploreObservationRealm *o = [ExploreObservationRealm objectForPrimaryKey:observationUUID];
    NSIndexPath *ip = [NSIndexPath indexPathForItem:[self.myObservations indexOfObject:o]
                                          inSection:0];
    
    if (ip && [self.tableView.indexPathsForVisibleRows containsObject:ip]) {
        [self.tableView reloadRowsAtIndexPaths:@[ ip ]
                              withRowAnimation:UITableViewRowAnimationNone];
    }
}


- (void)uploadSessionFailedFor:(NSString *)observationUUID error:(NSError *)error {
    [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"Upload - Fatal Error %@", error.localizedDescription]];
    
    if (observationUUID) {
        // clear progress for this upload
        self.uploadProgress[observationUUID] = nil;
    }
    
    // dirty the me user to force re-fetching
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.loginController dirtyLocalMeUser];
    
    // TODO: actually stop the upload
    [self syncStopped];
    
    if ([error.domain isEqualToString:INatJWTFailureErrorDomain]) {
        [self notifyUploadErrorJWTFetchFailed];
    } else if ([error.userInfo valueForKey:AFNetworkingOperationFailingURLResponseErrorKey]) {
        NSHTTPURLResponse *resp = [error.userInfo valueForKey:AFNetworkingOperationFailingURLResponseErrorKey];
        if (resp.statusCode == 401) {
            [self notifyUploadErrorAuthRequired];
        } else if (resp.statusCode == 403) {
            [self notifyUploadErrorSuspended];
        } else {
            [self notifyUploadErrorOtherError:error];
        }
    } else {
        [self notifyUploadErrorOtherError:error];
    }
    
    [self.tableView reloadData];
}


- (void)deleteSessionStarted:(ExploreDeletedRecord *)deletedRecord {
    [[Analytics sharedClient] debugLog:@"Upload - Delete Started"];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    [self configureHeaderForLoggedInUser];
    [self.meHeader startAnimatingUpload];
}

- (void)deleteSessionFinished {
    [[Analytics sharedClient] debugLog:@"Upload - Delete Session Finished"];
    
    // dirty the me user to force re-fetching
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.loginController dirtyLocalMeUser];
    [self configureHeaderForLoggedInUser];
    [self.meHeader stopAnimatingUpload];
    
    [self syncStopped];
}

- (void)deleteSessionFailedFor:(ExploreDeletedRecord *)deletedRecord error:(NSError *)error {
    [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"Upload - Delete Failed: %@", [error localizedDescription]]];
    
    // dirty the me user to force re-fetching
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.loginController dirtyLocalMeUser];
    
    [self syncStopped];
    
    if ([error.userInfo valueForKey:AFNetworkingOperationFailingURLResponseErrorKey]) {
        NSHTTPURLResponse *resp = [error.userInfo valueForKey:AFNetworkingOperationFailingURLResponseErrorKey];
        if (resp.statusCode == 401) {
            [self notifyUploadErrorAuthRequired];
        } else if (resp.statusCode == 403) {
            [self notifyUploadErrorSuspended];
        } else {
            [self notifyUploadErrorOtherError:error];
        }
    } else {
        [self notifyUploadErrorOtherError:error];
    }
}

#pragma mark - uploader delegate helpers

- (void)notifyUploadErrorJWTFetchFailed {
    [[Analytics sharedClient] debugLog:@"Upload - JWT Fetch Failed"];
    [[Analytics sharedClient] event:kAnalyticsEventSyncStopped
                     withProperties:@{
                         @"Via": @"JWT Fetch Failed",
                     }];
    
    NSString *title = NSLocalizedString(@"Upload Failed", @"upload failed alert title");
    NSString *message = NSLocalizedString(@"Fetching an authentication token failed. Please contact help@inaturalist.org and try later.",
                                          @"This is an explanation for when auth token fetch fails during upload/sync.");
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)notifyUploadErrorAuthRequired {
    [[Analytics sharedClient] debugLog:@"Upload - Auth Required"];
    [[Analytics sharedClient] event:kAnalyticsEventSyncStopped
                     withProperties:@{
                         @"Via": @"Auth Required",
                     }];
    
    NSString *title = NSLocalizedString(@"Upload Failed", @"upload failed alert title");
    NSString *baseMsg = NSLocalizedString(@"Unable to upload to iNaturalist, error 401 unauthenticated. Please contact help@inaturalist.org and try later.",
                                          @"This is an explanation for when we get a 401 during upload/sync.");
    
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    LoginController *login = [appDelegate loginController];
    NSString *jwtExists = (login.jwtToken && ![login.jwtToken isEqualToString:@""]) ? @"JWT" : @"No JWT";
    NSString *jwtDate = [login.jwtTokenExpiration description];
    NSString *furtherDetails = [NSString stringWithFormat:@"%@ %@", jwtExists, jwtDate];
    
    NSString *fullReasonMsg = [NSString stringWithFormat:@"%@ -  Debug: %@", baseMsg, furtherDetails];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:fullReasonMsg
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)notifyUploadErrorSuspended {
    [[Analytics sharedClient] debugLog:@"Upload - Forbidden"];
    [[Analytics sharedClient] event:kAnalyticsEventSyncStopped
                     withProperties:@{
                         @"Via": @"Auth Forbidden",
                     }];
    
    NSString *alertTitle = NSLocalizedString(@"Not Authorized", @"403 unauthorized title");
    NSString *alertMessage = NSLocalizedString(@"You don't have permission to do that. Your account may have been suspended. Please contact help@inaturalist.org.",
                                               @"403 forbidden message");
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                   message:alertMessage
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)notifyUploadErrorOtherError:(NSError *)error {
    NSString *alertTitle = NSLocalizedString(@"Whoops!", @"Default upload failure alert title.");
    NSString *alertMessage;
    
    if (error) {
        alertMessage = [NSString stringWithFormat:NSLocalizedString(@"Looks like there was an error: %@",nil), error.localizedDescription];
    } else {
        alertMessage = NSLocalizedString(@"There was an unexpected error.",
                                         @"Unresolvable and unknown error during observation upload.");
    }
    
    [[Analytics sharedClient] event:kAnalyticsEventSyncFailed
                     withProperties:@{
                         @"Alert": alertMessage,
                     }];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:alertTitle
                                                                   message:alertMessage
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}


@end
