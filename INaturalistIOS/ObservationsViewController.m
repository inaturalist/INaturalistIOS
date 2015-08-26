//
//  ObservationsViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/13/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <SVProgressHUD/SVProgressHUD.h>
#import <QBImagePickerController/QBImagePickerController.h>
#import <ImageIO/ImageIO.h>
#import <FontAwesomeKit/FAKIonIcons.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <CustomIOSAlertView/CustomIOSAlertView.h>
#import <SDWebImage/UIButton+WebCache.h>

#import "ObservationsViewController.h"
#import "LoginController.h"
#import "Observation.h"
#import "ObservationFieldValue.h"
#import "ObservationPageViewController.h"
#import "ObservationPhoto.h"
#import "ProjectObservation.h"
#import "Project.h"
#import "ImageStore.h"
#import "INatUITabBarController.h"
#import "INaturalistAppDelegate.h"
#import "RefreshControl.h"
#import "ObservationActivityViewController.h"
#import "UIImageView+WebCache.h"
#import "UIColor+INaturalist.h"
#import "Analytics.h"
#import "User.h"
#import "MeHeaderView.h"
#import "AnonHeaderView.h"
#import "INatWebController.h"
#import "SignupSplashViewController.h"
#import "LoginViewController.h"
#import "INaturalistAppDelegate+TransitionAnimators.h"
#import "UploadManagerNotificationDelegate.h"
#import "ObservationViewCell.h"


@interface ObservationsViewController () <NSFetchedResultsControllerDelegate, UploadManagerNotificationDelegate> {
    UIView *noContentView;

    NSFetchedResultsController *fetchedResultsController;
}
@property NSMutableArray *nonFatalUploadErrors;
@property RKObjectLoader *meObjectLoader;
@property MeHeaderView *meHeader;
@end

@implementation ObservationsViewController

- (void)presentSignupSplashWithReason:(NSString *)reason {
    [[Analytics sharedClient] event:kAnalyticsEventNavigateSignupSplash
                     withProperties:@{ @"From": @"Observations" }];

    SignupSplashViewController *splash = [[SignupSplashViewController alloc] initWithNibName:nil bundle:nil];
    splash.cancellable = YES;
    splash.reason = reason;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:splash];
    // for sizzle
    nav.delegate = (INaturalistAppDelegate *)[UIApplication sharedApplication].delegate;
    [self.tabBarController presentViewController:nav animated:YES completion:nil];
}

- (void)uploadOneObservation:(UIButton *)button {
    CGPoint buttonCenter = button.center;
    CGPoint translatedCenter = [self.tableView convertPoint:buttonCenter fromView:button.superview];
    NSIndexPath *ip = [self.tableView indexPathForRowAtPoint:translatedCenter];
    
    Observation *observation = [fetchedResultsController objectAtIndexPath:ip];
    
    [[Analytics sharedClient] event:kAnalyticsEventSyncObservation
                     withProperties:@{
                                      @"Via": @"Manual Single Upload",
                                      @"numDeletes": @(0),
                                      @"numUploads": @(1),
                                      }];

    [self uploadDeletes:@[]
                uploads:@[ observation ]];
}

- (IBAction)sync:(id)sender {
    
    if (self.isSyncing) {
        [self stopSyncPressed];
        return;
    }
    
    NSMutableArray *recordsToDelete = [NSMutableArray array];
    for (Class class in @[ [Observation class], [ObservationPhoto class], [ObservationFieldValue class], [ProjectObservation class] ]) {
        [recordsToDelete addObjectsFromArray:[DeletedRecord objectsWithPredicate:[NSPredicate predicateWithFormat:@"modelName = %@", \
                                                                                  NSStringFromClass(class)]]];
    }
    NSArray *recordsToUpload = [Observation needingUpload];
    
    [[Analytics sharedClient] event:kAnalyticsEventSyncObservation
                     withProperties:@{
                                      @"Via": @"Manual Full Upload",
                                      @"numDeletes": @(recordsToDelete.count),
                                      @"numUploads": @(recordsToUpload.count),
                                      }];


    [self uploadDeletes:recordsToDelete
                uploads:[Observation needingUpload]];
}

- (void)uploadDeletes:(NSArray *)observationsToDelete uploads:(NSArray *)observationsToUpload {
    
    if (self.isSyncing) {
        return;
    }
    
    if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Internet connection required",nil)
                                                     message:NSLocalizedString(@"You must be connected to the Internet to upload to iNaturalist.org",nil)
                                                    delegate:self 
                                           cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                           otherButtonTitles:nil];
        [av show];
        return;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:INatTokenPrefKey]) {
        [self presentSignupSplashWithReason:NSLocalizedString(@"You must be logged in to upload.", @"This is an explanation for why the upload button triggers a login prompt.")];
        return;
    }

    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    UploadManager *uploader = appDelegate.loginController.uploadManager;
    uploader.cancelled = NO;
    
    [uploader uploadDeletes:observationsToDelete completion:^{
        [uploader uploadObservations:observationsToUpload completion:nil];
    }];
}

- (void)appEnteredBackground {
    if (self.isSyncing) {
        [[Analytics sharedClient] event:kAnalyticsEventSyncStopped
                         withProperties:@{
                                          @"Via": @"App Entered Background",
                                          }];
        [self stopSync];
    }
}

- (void)stopSyncPressed {
    [[Analytics sharedClient] event:kAnalyticsEventSyncStopped
                     withProperties:@{
                                      @"Via": @"Stop Upload Button",
                                      }];
    
    [self stopSync];
}

- (void)stopSync
{
    // allow sleep
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    
    // notify the upload manager to cancel any outstanding work
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.loginController.uploadManager.cancelled = YES;
    
    [[self tableView] reloadData];
    self.tableView.scrollEnabled = YES;
    [self checkSyncStatus];
}

- (BOOL)isSyncing {
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    return appDelegate.loginController.uploadManager.isUploading;
    return [UIApplication sharedApplication].isIdleTimerDisabled;
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
}

- (void)refreshRequestedNotify:(BOOL)notify {
    
    if (![[[RKClient sharedClient] reachabilityObserver] isReachabilityDetermined] ||
        ![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {\
        
        if (notify) {
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"You must be connected to the Internet to upload to iNaturalist.org",nil)];
            [self.refreshControl endRefreshing];
        }
        
        return;
    }
    
    // make sure -itemsToSyncCount is current
    [self checkSyncStatus];
    
    NSInteger itemsToUpload = [[Observation needingUpload] count] + [Observation deletedRecordCount];
    itemsToUpload += [ObservationPhoto deletedRecordCount];
    itemsToUpload += [ProjectObservation deletedRecordCount];
    itemsToUpload += [ObservationFieldValue deletedRecordCount];
    
    if (itemsToUpload > 0) {
        // no implicit upload
        if (!notify) { return; }
        
        [[Analytics sharedClient] event:kAnalyticsEventObservationsPullToRefresh
                         withProperties:@{ @"ActionTaken" : @"Sync" }];
        [self.refreshControl endRefreshing];
        [self sync:nil];
    } else {
        [[Analytics sharedClient] event:kAnalyticsEventObservationsPullToRefresh
                         withProperties:@{ @"ActionTaken" : @"RefreshData" }];
        [self refreshData];
    }
}

- (void)refreshData
{
	NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:INatUsernamePrefKey];
	if (username.length) {
        [[Analytics sharedClient] debugLog:@"Network - Load an observation"];
		[[RKObjectManager sharedManager] loadObjectsAtResourcePath:[NSString stringWithFormat:@"/observations/%@.json?extra=observation_photos,projects,fields", username]
													 objectMapping:[Observation mapping]
														  delegate:self];
        [self loadUserForHeader];
        self.lastRefreshAt = [NSDate date];
	}
}

- (void)checkForDeleted {
	NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:INatUsernamePrefKey];
	if (username.length) {
		
		NSDate *lastSyncDate = [[NSUserDefaults standardUserDefaults] objectForKey:INatLastDeletedSync];
		if (!lastSyncDate) {
			// have never synced; use unix timestamp date of 0
			lastSyncDate = [NSDate dateWithTimeIntervalSince1970:0];
		}
		
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
		[dateFormatter setLocale:enUSPOSIXLocale];
		[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZZZZZ"];

		NSString *iso8601String = [dateFormatter stringFromDate:lastSyncDate];
		
        [[Analytics sharedClient] debugLog:@"Network - Get My Recent Observations"];
		[[RKClient sharedClient] get:[NSString stringWithFormat:@"/observations/%@?updated_since=%@", username, iso8601String] delegate:self];
	}
}

- (void)checkNewActivity
{
    [[Analytics sharedClient] debugLog:@"Network - Get My Updates Activity"];
	[[RKClient sharedClient] get:@"/users/new_updates.json?notifier_types=Identification,Comment&skip_view=true&resource_type=Observation" delegate:self];
}

- (void)loadData {
    // perform the iniital local fetch
    NSError *fetchError;
    [fetchedResultsController performFetch:&fetchError];
    if (fetchError) {
        [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"Error fetching: %@",
                                            fetchError.localizedDescription]];
        [SVProgressHUD showErrorWithStatus:fetchError.localizedDescription];
    }
}

- (void)reload
{
    [self loadData];
	[self checkEmpty];
    [[self tableView] reloadData];
}

- (void)checkSyncStatus
{
    if (self.isSyncing) {
        return;
    }
    
    if (self.navigationController.topViewController != self) {
        return;
    }
    
    [((INatUITabBarController *)self.tabBarController) setObservationsTabBadge];
}

- (void)checkEmpty
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [fetchedResultsController sections][0];      // only one section of observations in our tableview

    if ([sectionInfo numberOfObjects] == 0) {

        if (!noContentView) {
            noContentView = ({
                
                
                // leave room for the header
                UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 100.0f,
                                                                        self.tableView.frame.size.width,
                                                                        self.tableView.frame.size.height - 100.0f)];
                view.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
                
                view.backgroundColor = [UIColor whiteColor];
                
                UILabel *noObservations = ({
                    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
                    label.translatesAutoresizingMaskIntoConstraints = NO;
                    
                    label.textColor = [UIColor grayColor];
                    label.text = NSLocalizedString(@"Looks like you have no observations.", @"Notice to display to the user on the Me tab when they have no observations");
                    label.font = [UIFont systemFontOfSize:14.0f];
                    label.numberOfLines = 2;
                    label.textAlignment = NSTextAlignmentCenter;
                    
                    label;
                });
                [view addSubview:noObservations];
                
                UIImageView *binocs = ({
                    UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectZero];
                    iv.translatesAutoresizingMaskIntoConstraints = NO;
                    
                    iv.contentMode = UIViewContentModeScaleAspectFit;
                    iv.image = [[UIImage imageNamed:@"binocs"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                    iv.tintColor = [UIColor lightGrayColor];
                    
                    iv;
                });
                [view addSubview:binocs];
                
                NSDictionary *views = @{
                                        @"bottomLayout": self.bottomLayoutGuide,
                                        @"noObservations": noObservations,
                                        @"binocs": binocs,
                                        };
                
                [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[noObservations]-|"
                                                                             options:0
                                                                             metrics:0
                                                                               views:views]];
                [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[binocs]-|"
                                                                             options:0
                                                                             metrics:0
                                                                               views:views]];

                [view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-20-[noObservations(==20)]-0-[binocs]-100-|"
                                                                             options:0
                                                                             metrics:0
                                                                               views:views]];

                
                view;
            });
            
        }
        [self.view insertSubview:noContentView aboveSubview:self.tableView];
        [noContentView setNeedsLayout];

    } else if (noContentView) {
            [noContentView removeFromSuperview];
    }
}

- (void)handleNSManagedObjectContextDidSaveNotification:(NSNotification *)notification
{
    if (self.view && [self.navigationController.topViewController isEqual:self] &&
        ![[UIApplication sharedApplication] isIdleTimerDisabled] &&
        ![self.tabBarController presentedViewController]) {
        [self reload];
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
    Observation *o = [fetchedResultsController objectAtIndexPath:indexPath];
    ObservationActivityViewController *vc = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:NULL]
											 instantiateViewControllerWithIdentifier:@"ObservationActivityViewController"];
	vc.observation = o;
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)showError:(NSString *)errorMessage{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
}

- (void)viewActivity:(UIButton *)sender {
	
	UITableViewCell *cell = (UITableViewCell *)sender.superview.superview;
	NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    Observation *observation = [fetchedResultsController objectAtIndexPath:indexPath];
	
	ObservationActivityViewController *vc = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:NULL]
											 instantiateViewControllerWithIdentifier:@"ObservationActivityViewController"];
	vc.observation = observation;
    [self.navigationController pushViewController:vc animated:YES];
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
    
    // now is a good time to check that we're displaying up to date sync info
    if (!self.isSyncing) {
        [self checkSyncStatus];
    }
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:@[ newIndexPath ]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:@[ indexPath ]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self.tableView reloadRowsAtIndexPaths:@[ indexPath ]
                                  withRowAnimation:UITableViewRowAnimationNone];
            break;
            
        case NSFetchedResultsChangeMove:
            [self.tableView moveRowAtIndexPath:indexPath
                                   toIndexPath:newIndexPath];
            break;
            
        default:
            break;
    }
}


# pragma mark TableViewController methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    Observation *o = [fetchedResultsController objectAtIndexPath:indexPath];
    
    ObservationViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ObservationTableCell"];
    
    if (o.sortedObservationPhotos.count > 0) {
        ObservationPhoto *op = [o.sortedObservationPhotos objectAtIndex:0];
		if (op.photoKey == nil) {
            [cell.observationImage sd_setImageWithURL:[NSURL URLWithString:op.squareURL]];
		} else {
			cell.observationImage.image = [[ImageStore sharedImageStore] find:op.photoKey forSize:ImageStoreSquareSize];
            
            // if we can't find a square image...
            if (!cell.observationImage.image) {
                // ...try again a few times, it's probably a new image in the process of being cut-down
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if ([[tableView indexPathsForVisibleRows] containsObject:indexPath]) {
                        [tableView reloadRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationNone];
                    }
                });
            }
		}
        
    } else {
        cell.observationImage.image = [[ImageStore sharedImageStore] iconicTaxonImageForName:o.iconicTaxonName];
    }
    
    if (o.speciesGuess && o.speciesGuess.length > 0) {
        [cell.titleLabel setText:o.speciesGuess];
    } else {
        [cell.titleLabel setText:NSLocalizedString(@"Something...",nil)];
    }
    
    if (o.placeGuess && o.placeGuess.length > 0) {
        cell.subtitleLabel.text = o.placeGuess;
    } else if (o.latitude) {
        cell.subtitleLabel.text = [NSString stringWithFormat:@"%@, %@", o.latitude, o.longitude];
    } else {
        cell.subtitleLabel.text = NSLocalizedString(@"Somewhere...",nil);
    }
    
	if (o.hasUnviewedActivity.boolValue) {
		// make bubble red
		[cell.activityButton setBackgroundImage:[UIImage imageNamed:@"08-chat-red"] forState:UIControlStateNormal];
	} else {
		// make bubble grey
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
	
    cell.dateLabel.text = o.observedOnShortString;
    cell.syncImage.hidden = !o.needsSync;
    
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (o.needsUpload) {
        cell.uploadButton.hidden = NO;
        
        cell.activityButton.hidden = YES;
        cell.syncImage.hidden = YES;
        cell.dateLabel.hidden = YES;
        
        [cell.uploadButton addTarget:self
                              action:@selector(uploadOneObservation:)
                    forControlEvents:UIControlEventTouchUpInside];
        
        cell.subtitleLabel.text = NSLocalizedString(@"Waiting to upload...", @"Subtitle for observation when waiting to upload.");
        if ([appDelegate.loginController.uploadManager isUploading]) {
            cell.uploadButton.enabled = NO;
        } else {
            cell.uploadButton.enabled = YES;
        }
    } else {
        cell.uploadButton.hidden = YES;
        cell.dateLabel.hidden = NO;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 54.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 100.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:INatUsernamePrefKey];
    if (username && ![username isEqualToString:@""]) {
        if (!self.meHeader) {
            self.meHeader = [[MeHeaderView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 100.0f)];
        }
        
        [self configureHeaderForLoggedInUser];
        
        [self.meHeader.projectsButton addTarget:self
                                         action:@selector(tappedProjects)
                               forControlEvents:UIControlEventTouchUpInside];
        [self.meHeader.guidesButton addTarget:self
                                       action:@selector(tappedGuides)
                             forControlEvents:UIControlEventTouchUpInside];

        return self.meHeader;
        
    } else {
        AnonHeaderView *header = [[AnonHeaderView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 100.0f)];
        header.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        
        [header.signupButton bk_addEventHandler:^(id sender) {
            
            [[Analytics sharedClient] event:kAnalyticsEventNavigateSignup
                             withProperties:@{ @"from": @"AnonMeHeader" }];
            
            [self presentSignupSplashWithReason:nil];
            
        } forControlEvents:UIControlEventTouchUpInside];
        
        [header.loginButton bk_addEventHandler:^(id sender) {
            
            [[Analytics sharedClient] event:kAnalyticsEventNavigateLogin
                             withProperties:@{ @"from": @"AnonMeHeader" }];
            
            LoginViewController *login = [[LoginViewController alloc] initWithNibName:nil bundle:nil];
            login.cancellable = YES;
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:login];
            nav.delegate = (INaturalistAppDelegate *)[UIApplication sharedApplication].delegate;
            [self presentViewController:nav animated:YES completion:nil];

        } forControlEvents:UIControlEventTouchUpInside];
        
        return header;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    Observation *o = [fetchedResultsController objectAtIndexPath:indexPath];
    if ([appDelegate.loginController.uploadManager isUploading] && o.needsUpload) {
        return;
    } else {
        [self performSegueWithIdentifier:@"observationDetail" sender:o];
    }
}

#pragma mark - Header helpers

- (void)tappedProjects {
    [self performSegueWithIdentifier:@"segueToProjects" sender:nil];
}

- (void)tappedGuides {
    [self performSegueWithIdentifier:@"segueToGuides" sender:nil];
}

- (void)configureHeaderForLoggedInUser {
    NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:INatUsernamePrefKey];
    if (username && username.length > 0) {
        NSFetchRequest *meFetch = [[NSFetchRequest alloc] initWithEntityName:@"User"];
        meFetch.predicate = [NSPredicate predicateWithFormat:@"login == %@", username];
        NSError *fetchError;
        User *me = [[[User managedObjectContext] executeFetchRequest:meFetch error:&fetchError] firstObject];
        if (fetchError) {
            [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"error fetching: %@",
                                                fetchError.localizedDescription]];
            [SVProgressHUD showErrorWithStatus:fetchError.localizedDescription];
        }
        
        if (me) {
            [self configureHeaderView:self.meHeader forUser:me];
        }
    }
}

- (void)configureHeaderView:(MeHeaderView *)view forUser:(User *)user {
    NSUInteger needingUploadCount = [[Observation needingUpload] count];
    NSUInteger needingDeleteCount = [Observation deletedRecordCount];
    
    if (needingUploadCount > 0 || needingDeleteCount > 0) {
        [view.iconButton setImage:nil forState:UIControlStateNormal];
        [view.iconButton sd_setBackgroundImageWithURL:nil forState:UIControlStateNormal];
        [view.iconButton setTintColor:[UIColor whiteColor]];
        view.iconButton.backgroundColor = [UIColor inatTint];

        if (self.isSyncing) {
            FAKIcon *stopIcon = [FAKIonIcons iosCloseOutlineIconWithSize:50];
            [view.iconButton setAttributedTitle:stopIcon.attributedString
                                       forState:UIControlStateNormal];
            
            [view startAnimatingUpload];
            
            view.obsCountLabel.text = NSLocalizedString(@"Uploading observations...", @"Title of me header while uploading observations.");
            
        } else {
            FAKIcon *uploadIcon = [FAKIonIcons iosCloudUploadIconWithSize:50];
            if (![[view.iconButton attributedTitleForState:UIControlStateNormal] isEqualToAttributedString:uploadIcon.attributedString]) {
                
                [view.iconButton setAttributedTitle:uploadIcon.attributedString
                                           forState:UIControlStateNormal];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [UIView animateWithDuration:0.3f
                                     animations:^{
                                         view.iconButton.transform = CGAffineTransformMakeScale(1.2f, 1.2f);
                                     } completion:^(BOOL finished) {
                                         [UIView animateWithDuration:0.3f
                                                          animations:^{
                                                              view.iconButton.transform = CGAffineTransformIdentity;
                                                          }];
                                     }];
                });
            }
            
            if (needingUploadCount > 0 && needingDeleteCount > 0) {
                NSString *baseUploadAndDeleteCountStr = NSLocalizedString(@"%d To Upload, %d To Delete",
                                                                          @"Count of observations to upload and delete.");
                view.obsCountLabel.text = [NSString stringWithFormat:baseUploadAndDeleteCountStr, needingUploadCount, needingDeleteCount];
            } else if (needingUploadCount > 0) {
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
                NSString *baseDeleteCountStr;
                if (needingDeleteCount == 1) {
                    baseDeleteCountStr = NSLocalizedString(@"%d Delete to Sync",
                                                           @"Count of deletes to upload, singular.");
                } else {
                    baseDeleteCountStr = NSLocalizedString(@"%d Deletes To Sync",
                                                           @"Count of observations to upload, plural.");
                }
                view.obsCountLabel.text = [NSString stringWithFormat:baseDeleteCountStr, needingDeleteCount];
            }
        }
        
        if (![view.iconButton targetForAction:@selector(sync:) withSender:self]) {
            [view.iconButton addTarget:self
                                action:@selector(sync:)
                      forControlEvents:UIControlEventTouchUpInside];
        }
        
    } else {
        [view.iconButton setAttributedTitle:nil forState:UIControlStateNormal];
        view.iconButton.backgroundColor = [UIColor clearColor];
        [view.iconButton removeTarget:self
                               action:@selector(sync:)
                     forControlEvents:UIControlEventTouchUpInside];
        
        // icon
        if (user.mediumUserIconURL && ![user.mediumUserIconURL isEqualToString:@""]) {
            [view.iconButton sd_setBackgroundImageWithURL:[NSURL URLWithString:user.mediumUserIconURL]
                                                 forState:UIControlStateNormal];
        } else if (user.userIconURL && ![user.userIconURL isEqualToString:@""]) {
            [view.iconButton sd_setBackgroundImageWithURL:[NSURL URLWithString:user.userIconURL]
                                                 forState:UIControlStateNormal];
        } else {
            FAKIcon *person = [FAKIonIcons iosPersonIconWithSize:80.0f];
            [person addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor]];
            [view.iconButton setImage:[person imageWithSize:CGSizeMake(80, 80)]
                             forState:UIControlStateNormal];
        }
        
        // observation count
        if (user.observationsCount.integerValue > 0) {
            NSString *baseObsCountStr;
            if (user.observationsCount.integerValue == 1) {
                baseObsCountStr = NSLocalizedString(@"%d Observation", @"Count of observations by this user, singular.");
            } else {
                baseObsCountStr = NSLocalizedString(@"%d Observations", @"Count of observations by this user, plural.");
            }
            view.obsCountLabel.text = [NSString stringWithFormat:baseObsCountStr, user.observationsCount.integerValue];
        } else {
            view.obsCountLabel.text = NSLocalizedString(@"No Observations", @"Header observation count title when there are none.");
        }
    }
}

- (void)loadUserForHeader {
    NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:INatUsernamePrefKey];
    if (username) {
        
        self.navigationItem.title = username;
        
        if ([[[RKClient sharedClient] reachabilityObserver] isReachabilityDetermined] && [[RKClient sharedClient]  isNetworkReachable]) {
            
            NSString *path = [NSString stringWithFormat:@"/people/%@.json", username];
            
            [[Analytics sharedClient] debugLog:@"Network - Load me for header"];
            [[RKObjectManager sharedManager] loadObjectsAtResourcePath:path
                                                         objectMapping:[User mapping]
                                                              delegate:self];
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

#pragma mark - View lifecycle

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.navigationController.tabBarItem.image = ({
            FAKIcon *meOutline = [FAKIonIcons iosPersonOutlineIconWithSize:35];
            [meOutline addAttribute:NSForegroundColorAttributeName value:[UIColor inatInactiveGreyTint]];
            [[meOutline imageWithSize:CGSizeMake(34, 45)] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        });
        
        self.navigationController.tabBarItem.selectedImage =({
            FAKIcon *meFilled = [FAKIonIcons iosPersonIconWithSize:35];
            [meFilled addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
            [meFilled imageWithSize:CGSizeMake(34, 45)];
        });
        
        self.navigationController.tabBarItem.title = NSLocalizedString(@"Me", nil);
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

// if you need to test syncing lots of obs with the fetched results controller, do:
//    [Observation deleteAll];
//    for (int i = 0; i < 50; i++) {
//        [Observation object];
//    }
//    NSError *error;
//    [[[RKObjectManager sharedManager] objectStore] save:&error];
//    if (error) {
//        NSLog(@"ALERT: %@", error.localizedDescription);
//    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userSignedIn)
                                                 name:kUserLoggedInNotificationName
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appEnteredBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    // NSFetchedResultsController request for my observations
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Observation"];
    
    // sort by common name, if available
    request.sortDescriptors = @[
                                [[NSSortDescriptor alloc] initWithKey:@"sortable" ascending:NO],
                                [[NSSortDescriptor alloc] initWithKey:@"recordID" ascending:NO],
                                ];
    
    // no request predicate yet, all Observations in core data are "mine"
    
    // setup our fetched results controller
    fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                   managedObjectContext:[NSManagedObjectContext defaultContext]
                                                                     sectionNameKeyPath:nil
                                                                              cacheName:nil];
    // update our tableview based on changes in the fetched results
    fetchedResultsController.delegate = self;
    
    // perform the iniital local fetch
    NSError *fetchError;
    [fetchedResultsController performFetch:&fetchError];
    if (fetchError) {
        [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"fetch error: %@",
                                            fetchError.localizedDescription]];
        [SVProgressHUD showErrorWithStatus:fetchError.localizedDescription];
    }
    
    self.navigationItem.leftBarButtonItem = nil;
    FAKIcon *settings = [FAKIonIcons iosGearOutlineIconWithSize:30];
    UIImage *settingsImage = [settings imageWithSize:CGSizeMake(30, 30)];
    settings.iconFontSize = 20;
    UIImage *settingsLandscapeImage = [settings imageWithSize:CGSizeMake(20, 20)];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:settingsImage
                                                                landscapeImagePhone:settingsLandscapeImage
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(settings)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNSManagedObjectContextDidSaveNotification:) 
                                                 name:NSManagedObjectContextDidSaveNotification 
                                               object:[Observation managedObjectContext]];
    
    
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.loginController.uploadManager setDelegate:self];
    
    [self loadUserForHeader];
}

- (void)userSignedIn {
    [self refreshRequestedNotify:YES];
}

- (void)settings {
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    UIViewController *vc = [storyBoard instantiateViewControllerWithIdentifier:@"Settings"];
    [self.navigationController pushViewController:vc animated:YES];
}


- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    
    // re-using 'firstSignInSeen' BOOL, which used to be set during the initial launch
    // when the user saw the login prompt for the first time.
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"firstSignInSeen"]) {
        
        // completely new users default to categorization on
        [[NSUserDefaults standardUserDefaults] setBool:YES
                                                forKey:kInatCategorizeNewObsPrefKey];
        
        // completely new users default to autocomplete on
        [[NSUserDefaults standardUserDefaults] setBool:YES
                                                forKey:kINatAutocompleteNamesPrefKey];
        
        [[NSUserDefaults standardUserDefaults] setBool:YES
                                                  forKey:@"firstSignInSeen"];
        [[NSUserDefaults standardUserDefaults] setBool:YES
                                                forKey:@"seenVersion254"];

        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    // new settings as of 2.5.4, for existing users
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"seenVersion254"]) {
        
        // existing users default to categorization on
        [[NSUserDefaults standardUserDefaults] setBool:YES
                                                forKey:kInatCategorizeNewObsPrefKey];

        // existing users default to autocomplete off
        [[NSUserDefaults standardUserDefaults] setBool:NO
                                                forKey:kINatAutocompleteNamesPrefKey];

        [[NSUserDefaults standardUserDefaults] setBool:YES
                                                forKey:@"seenVersion254"];
        
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    [self.navigationController setToolbarHidden:YES animated:YES];
    
    self.navigationController.navigationBar.translucent = NO;
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor inatTint];
    
	NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:INatUsernamePrefKey];
    if (username.length) {
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
    
    [self reload];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!self.isSyncing) {
        [self checkSyncStatus];
    }
    // automatically sync if there's network and we haven't synced in the last hour
    CGFloat minutes = 60,
    seconds = minutes * 60;
    NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:INatUsernamePrefKey];
    if (username.length &&
        [[[RKClient sharedClient] reachabilityObserver] isReachabilityDetermined] &&
        [[[RKClient sharedClient] reachabilityObserver] isNetworkReachable] &&
        (!self.lastRefreshAt || [self.lastRefreshAt timeIntervalSinceNow] < -1*seconds)) {
        [self refreshRequestedNotify:NO];
        [self checkForDeleted];
        [self checkNewActivity];
        [self loadUserForHeader];
    }

    [[Analytics sharedClient] timedEvent:kAnalyticsEventNavigateObservations];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];    
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
    [[Analytics sharedClient] endTimedEvent:kAnalyticsEventNavigateObservations];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIDeviceOrientationPortrait);
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"observationDetail"]) {
        ObservationDetailViewController *ovc = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"ObservationDetailViewController"];
        ObservationPageViewController *pvc = [segue destinationViewController];
        [ovc setDelegate:self];
        Observation *o = (Observation *)sender;
        [ovc setObservation:o];
        [pvc setViewControllers:[NSArray arrayWithObject:ovc]
                       direction:UIPageViewControllerNavigationDirectionForward
                        animated:YES
                      completion:nil];
    }
}

- (void)dealloc {
    [[[RKClient sharedClient] requestQueue] cancelRequestsWithDelegate:self];
}

#pragma mark - RKObjectLoaderDelegate
- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects
{
    if ([objectLoader.URL.absoluteString rangeOfString:@"/people/"].location != NSNotFound) {
        // got me object
        
        NSError *saveError;
        [[[RKObjectManager sharedManager] objectStore] save:&saveError];
        if (saveError) {
            [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"save error: %@",
                                                saveError.localizedDescription]];
            [SVProgressHUD showErrorWithStatus:saveError.localizedDescription];
        }
        
        // triggers reconfiguration of the header
        [self.tableView reloadData];

        return;
    }
    
	[self.refreshControl endRefreshing];
    if (objects.count == 0) return;
    NSDate *now = [NSDate date];
    for (INatModel *o in objects) {
		if ([o isKindOfClass:[Observation class]]) {
			Observation *observation = (Observation *)o;
            DeletedRecord *dr = [DeletedRecord objectWithPredicate:[NSPredicate predicateWithFormat:@"modelName == 'Observation' AND recordID = %@", o.recordID]];
            if (dr) {
                [o destroy];
                continue;
            }
			if (observation.localUpdatedAt == nil || !observation.needsSync) { // this only occurs for downloaded items, not locally updated items
				[observation setSyncedAt:now];
			}
			NSArray *sortedObservationPhotos = observation.sortedObservationPhotos;
			for (ObservationPhoto *photo in sortedObservationPhotos) {
				if (photo.localUpdatedAt == nil || !photo.needsSync) { // this only occurs for downloaded items, not locally updated items
					[photo setSyncedAt:now];
				}
			}
            for (ObservationFieldValue *ofv in observation.observationFieldValues) {
                if (ofv.needsSync) {
                    [[INatModel managedObjectContext] refreshObject:ofv mergeChanges:NO];
                } else {
                    ofv.syncedAt = now;
                }
			}
		}
        
        // don't update records that need to be synced
        if (o.needsSync) {
            [[INatModel managedObjectContext] refreshObject:o mergeChanges:NO];
        }
    }
    
    NSError *error = nil;
    [[[RKObjectManager sharedManager] objectStore] save:&error];
	
	// check for new activity
	[self checkNewActivity];
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {

    if ([objectLoader.URL.absoluteString rangeOfString:@"/people/"].location != NSNotFound) {
        // was running into a bug in release build config where the object loader was
        // getting deallocated after handling an error.  This is a kludge.
        self.meObjectLoader = objectLoader;

        // silently do nothing
        [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"load Me error: %@",
                                            error.localizedDescription]];

        return;
    }
	
    NSString *errorMsg;
    bool jsonParsingError = false, authFailure = false;
    switch (objectLoader.response.statusCode) {
        // UNPROCESSABLE ENTITY
        case 422:
            errorMsg = NSLocalizedString(@"Unprocessable entity",nil);
            break;
            
        default:
            // KLUDGE!! RestKit doesn't seem to handle failed auth very well
            jsonParsingError = [error.domain isEqualToString:@"JKErrorDomain"] && error.code == -1;
            authFailure = [error.domain isEqualToString:@"NSURLErrorDomain"] && error.code == -1012;
            errorMsg = error.localizedDescription;
    }
    
    if (self.isSyncing || self.refreshControl.isRefreshing) {
        NSString *msg, *title;
        if (error.code == -1004 || ([error.domain isEqualToString:@"org.restkit.RestKit.ErrorDomain"] && error.code == 2)) {
            title = NSLocalizedString(@"Internet connection required", nil);
            msg = NSLocalizedString(@"You must be connected to the Internet to do this.", nil);
        } else {
            title = NSLocalizedString(@"Whoops!",nil);
            msg = [NSString stringWithFormat:NSLocalizedString(@"Looks like there was an error: %@",nil), errorMsg];
        }
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:title
                                                     message:msg
                                                    delegate:self
                                           cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                           otherButtonTitles:nil];
        [av show];
    }
    [self.refreshControl endRefreshing];
}

#pragma mark - RKRequestDelegate

- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response
{
	if (response.allHeaderFields[@"X-Deleted-Observations"]) {
		NSString *deletedString = response.allHeaderFields[@"X-Deleted-Observations"];
		NSArray *recordIDs = [deletedString componentsSeparatedByString:@","];
		NSArray *records = [Observation matchingRecordIDs:recordIDs];
		for (INatModel *record in records) {
			[record destroy];
		}
		
		[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:INatLastDeletedSync];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
	
	if ([request.resourcePath rangeOfString:@"new_updates.json"].location != NSNotFound && (response.statusCode == 200 || response.statusCode == 304)) {
		NSString *jsonString = [[NSString alloc] initWithData:response.body
                                                     encoding:NSUTF8StringEncoding];
        NSError* error = nil;
        id<RKParser> parser = [[RKParserRegistry sharedRegistry] parserForMIMEType:@"application/json"];
        id parsedData = [parser objectFromString:jsonString error:&error];
		NSDate *now = [NSDate date];
		if (parsedData && [parsedData isKindOfClass:[NSDictionary class]] && !error) {
			NSNumber *recordID = ((NSDictionary *)parsedData)[@"id"];
			Observation *observation = [Observation objectWithPredicate:[NSPredicate predicateWithFormat:@"recordID == %@", recordID]];
			observation.hasUnviewedActivity = [NSNumber numberWithBool:YES];
            observation.syncedAt = now;
			[[[RKObjectManager sharedManager] objectStore] save:&error];
		} else if (parsedData && [parsedData isKindOfClass:[NSArray class]] && !error) {
			for (NSDictionary *notification in (NSArray *)parsedData) {
				NSNumber *recordID = notification[@"resource_id"];
				Observation *observation = [Observation objectWithPredicate:[NSPredicate predicateWithFormat:@"recordID == %@", recordID]];
				observation.hasUnviewedActivity = [NSNumber numberWithBool:YES];
                observation.syncedAt = now;
			}
			[[[RKObjectManager sharedManager] objectStore] save:&error];
		}
	} else {
		NSLog(@"Received status code %ld for %@", (long)response.statusCode, request.resourcePath);
	}
}

- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error
{
	NSLog(@"Request Error: %@", error.localizedDescription);
}

#pragma mark - Upload


- (void)uploadSessionAuthRequired {
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    
    [[Analytics sharedClient] event:kAnalyticsEventSyncStopped
                     withProperties:@{
                                      @"Via": @"Auth Required",
                                      }];
    [self stopSync];
    
    NSString *reasonMsg = NSLocalizedString(@"You must be logged in to upload to iNaturalist.org.",
                                            @"This is an explanation for why the sync button triggers a login prompt.");
    [self presentSignupSplashWithReason:reasonMsg];
}

- (void)uploadSessionFinished {
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];

    [self.meHeader stopAnimatingUpload];

    [[Analytics sharedClient] event:kAnalyticsEventSyncStopped
                     withProperties:@{
                                      @"Via": @"Upload Complete",
                                      }];
    
    
    if (self.nonFatalUploadErrors && self.nonFatalUploadErrors.count > 0) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Heads up",nil)
                                                     message:[self.nonFatalUploadErrors componentsJoinedByString:@"\n\n"]
                                                    delegate:self
                                           cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                           otherButtonTitles:nil];
        [av show];
        
        [self.nonFatalUploadErrors removeAllObjects];
    }
    
    
    // allow any pending upload animations to finish
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{        
        // make sure any deleted records get gone
        NSError *error = nil;
        [[[RKObjectManager sharedManager] objectStore] save:&error];

        [self stopSync];
        [self loadUserForHeader];
    });
}

- (void)uploadStartedFor:(Observation *)observation {
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    
    FAKIcon *stopIcon = [FAKIonIcons iosCloseOutlineIconWithSize:50];
    [self.meHeader.iconButton setAttributedTitle:stopIcon.attributedString
                                        forState:UIControlStateNormal];
    [self.meHeader startAnimatingUpload];
    self.meHeader.obsCountLabel.text = NSLocalizedString(@"Uploading observations...", @"Title of me header while uploading observations.");


    NSIndexPath *ip = [fetchedResultsController indexPathForObject:observation];
    ObservationViewCell *cell = (ObservationViewCell *)[self.tableView cellForRowAtIndexPath:ip];
    if ([self.tableView.visibleCells containsObject:cell]) {
        cell.subtitleLabel.hidden = NO;
        cell.dateLabel.hidden = YES;
        cell.uploadButton.hidden = YES;
        cell.uploadSpinner.hidden = NO;
        [cell.uploadSpinner startAnimating];
        cell.subtitleLabel.text = NSLocalizedString(@"Uploading...", @"subtitle for observation while it's uploading.");
    }
}

- (void)uploadSuccessFor:(Observation *)observation {
    
    [self configureHeaderForLoggedInUser];
    
    NSIndexPath *ip = [fetchedResultsController indexPathForObject:observation];
    ObservationViewCell *cell = (ObservationViewCell *)[self.tableView cellForRowAtIndexPath:ip];
    
    if ([self.tableView.visibleCells containsObject:cell]) {
        cell.subtitleLabel.hidden = NO;
        cell.dateLabel.hidden = NO;
        cell.uploadSpinner.hidden = YES;
        [cell.uploadSpinner stopAnimating];
        
        cell.subtitleLabel.text = NSLocalizedString(@"Finished", @"subtitle for observation after it's finished uploading.");
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if ([self.tableView.visibleCells containsObject:cell]) {
                [self.tableView reloadRowsAtIndexPaths:@[ ip ]
                                      withRowAnimation:UITableViewRowAnimationFade];
            }
        });
    }
}

- (void)uploadProgress:(float)progress for:(Observation *)observation {
    NSIndexPath *ip = [fetchedResultsController indexPathForObject:observation];
    ObservationViewCell *cell = (ObservationViewCell *)[self.tableView cellForRowAtIndexPath:ip];
    if ([self.tableView.visibleCells containsObject:cell]) {
        cell.subtitleLabel.hidden = NO;
        cell.dateLabel.hidden = YES;
        cell.uploadButton.hidden = YES;
        cell.uploadSpinner.hidden = NO;
        [cell.uploadSpinner startAnimating];
        cell.subtitleLabel.text = NSLocalizedString(@"Uploading...", @"subtitle for observation while it's uploading.");
    }
}

- (void)uploadNonFatalError:(NSError *)error {
    if (!self.nonFatalUploadErrors) {
        self.nonFatalUploadErrors = [[NSMutableArray alloc] init];
    }
    [self.nonFatalUploadErrors addObject:error.localizedDescription];
}

- (void)uploadFailedFor:(INatModel *)object error:(NSError *)error {
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    
    if ([object isKindOfClass:ProjectObservation.class]) {
        ProjectObservation *po = (ProjectObservation *)object;
        if (!self.nonFatalUploadErrors) {
            self.nonFatalUploadErrors = [[NSMutableArray alloc] init];
        }
        [self.nonFatalUploadErrors addObject:[NSString stringWithFormat:NSLocalizedString(@"%@ (%@) couldn't be added to project %@: %@",nil),
                                              po.observation.speciesGuess,
                                              po.observation.observedOnShortString,
                                              po.project.title,
                                              error.localizedDescription]];
        [po deleteEntity];
        
    } else if ([object isKindOfClass:ObservationFieldValue.class]) {
        // HACK: not sure where these observationless OFVs are coming from, so I'm just deleting
        // them and hoping for the best. I did add some Flurry logging for ofv creation, though.
        // kueda 20140112
        ObservationFieldValue *ofv = (ObservationFieldValue *)object;
        if (!ofv.observation) {
            NSLog(@"ERROR: deleted mysterious ofv: %@", ofv);
            [ofv deleteEntity];
        }
    } else if ([self isSyncing]) {
        NSString *alertTitle = NSLocalizedString(@"Whoops!", @"Default upload failure alert title.");
        NSString *alertMessage;
        
        if (error) {
            if (error.domain == RKErrorDomain && error.code == RKRequestConnectionTimeoutError) {
                alertTitle = NSLocalizedString(@"Request timed out",nil);
                alertMessage = NSLocalizedString(@"This can happen when your Internet connection is slow or intermittent.  Please try again the next time you're on WiFi.",nil);
            } else {
                alertMessage = [NSString stringWithFormat:NSLocalizedString(@"Looks like there was an error: %@",nil), error.localizedDescription];
            }
        } else {
            alertMessage = NSLocalizedString(@"There was an unexpected error.",
                                             @"Unresolvable and unknown error during observation upload.");
        }
        
        [[Analytics sharedClient] event:kAnalyticsEventSyncFailed
                         withProperties:@{
                                          @"Alert": alertMessage,
                                          }];
        [self stopSync];
        
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:alertTitle
                                                     message:alertMessage
                                                    delegate:self
                                           cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                           otherButtonTitles:nil];
        [av show];
    }
}

- (void)deleteStartedFor:(DeletedRecord *)deletedRecord {
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    FAKIcon *stopIcon = [FAKIonIcons iosCloseOutlineIconWithSize:50];
    [self.meHeader.iconButton setAttributedTitle:stopIcon.attributedString
                                        forState:UIControlStateNormal];
    [self.meHeader startAnimatingUpload];
    self.meHeader.obsCountLabel.text = NSLocalizedString(@"Syncing deletes...", @"Title of me header while syncing deletes.");
}

- (void)deleteSuccessFor:(DeletedRecord *)deletedRecord {
    [self configureHeaderForLoggedInUser];
}

- (void)deleteSessionFinished {
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    [self.meHeader stopAnimatingUpload];
    [self.tableView reloadData];
}

- (void)deleteFailedFor:(DeletedRecord *)deletedRecord error:(NSError *)error {
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];

    NSString *alertTitle = NSLocalizedString(@"Deleted Failed", @"Delete failed message");
    NSString *alertMsg;
    if (error) {
        alertMsg = error.localizedDescription;
    } else {
        alertMsg = NSLocalizedString(@"Uknown error while attempting to delete.", @"uknonwn delete error");
    }
    
    [[[UIAlertView alloc] initWithTitle:alertTitle
                                message:alertMsg
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"OK", nil)
                      otherButtonTitles:nil] show];
}

@end
