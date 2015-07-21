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

static const int ObservationCellImageTag = 5;
static const int ObservationCellTitleTag = 1;
static const int ObservationCellSubTitleTag = 2;
static const int ObservationCellUpperRightTag = 3;
static const int ObservationCellLowerRightTag = 4;
static const int ObservationCellActivityButtonTag = 6;
static const int ObservationCellActivityInteractiveButtonTag = 7;

@interface ObservationsViewController () <NSFetchedResultsControllerDelegate, UploadManagerNotificationDelegate> {
    UIView *noContentView;

    NSFetchedResultsController *fetchedResultsController;
}
@property UploadManager *uploadManager;
@property NSMutableArray *nonFatalUploadErrors;
@property RKObjectLoader *meObjectLoader;
@end

@implementation ObservationsViewController
@synthesize syncButton = _syncButton;
@synthesize observationsToSyncCount = _observationsToSyncCount;
@synthesize observationPhotosToSyncCount = _observationPhotosToSyncCount;
@synthesize syncToolbarItems = _syncToolbarItems;
@synthesize editButton = _editButton;
@synthesize stopSyncButton = _stopSyncButton;
@synthesize lastRefreshAt = _lastRefreshAt;

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

- (IBAction)sync:(id)sender {
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
    
    
    [[Analytics sharedClient] event:kAnalyticsEventSyncObservation];

    UploadManager *uploader = [[UploadManager alloc] initWithDelegate:self];
    if (!self.uploadManager) {
        self.uploadManager = uploader;
    }
    
    NSMutableArray *recordsToDelete = [NSMutableArray array];
    for (Class class in @[ [Observation class], [ObservationPhoto class], [ObservationFieldValue class], [ProjectObservation class] ]) {
        [recordsToDelete addObjectsFromArray:[DeletedRecord objectsWithPredicate:[NSPredicate predicateWithFormat:@"modelName = %@", \
                                                                                  NSStringFromClass(class)]]];
    }
    
    [uploader uploadDeletes:recordsToDelete completion:^{
        [uploader uploadObservations:[Observation needingUpload]];
    }];
    
    if (!self.stopSyncButton) {
        self.stopSyncButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Stop upload", @"Button to stop in-progress upload.")
                                                               style:UIBarButtonItemStyleBordered
                                                              target:self
                                                              action:@selector(stopSync)];
        self.stopSyncButton.tintColor = [UIColor redColor];
    }
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [self.navigationController setToolbarHidden:NO];
    [self setToolbarItems:[NSArray arrayWithObjects:flex, self.stopSyncButton, flex, nil]
                 animated:YES];
    
    // temporarily disable user interaction with most of the UI
    self.tableView.userInteractionEnabled = NO;
    self.tabBarController.tabBar.userInteractionEnabled = NO;
    self.navigationController.navigationBar.userInteractionEnabled = NO;
}

- (void)stopSync
{
    [SVProgressHUD dismiss];
    
    self.tableView.userInteractionEnabled = YES;
    self.tabBarController.tabBar.userInteractionEnabled = YES;
    self.navigationController.navigationBar.userInteractionEnabled = YES;

    if (self.uploadManager) {
        [self.uploadManager stop];
        self.uploadManager = nil;
    }
    [[self tableView] reloadData];
    self.tableView.scrollEnabled = YES;
    [self checkSyncStatus];
}

- (BOOL)isSyncing
{
    return [UIApplication sharedApplication].isIdleTimerDisabled;
}

- (IBAction)edit:(id)sender {
    if (self.isSyncing) {
        [self stopSync];
    }
    if ([self isEditing]) {
        [self stopEditing];
    } else {
        [sender setTitle:NSLocalizedString(@"Done",nil)];
        [(UIBarButtonItem *)sender setStyle:UIBarButtonItemStyleDone];
        [self setEditing:YES animated:YES];
    }
}

- (void)stopEditing
{
    [self.editButton setTitle:NSLocalizedString(@"Edit",nil)];
    [self.editButton setStyle:UIBarButtonItemStyleBordered];
    [self setEditing:NO animated:YES];
    [self checkSyncStatus];
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
    if ([self itemsToSyncCount] > 0) {
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
		
		[[RKClient sharedClient] get:[NSString stringWithFormat:@"/observations/%@?updated_since=%@", username, iso8601String] delegate:self];
	}
}

- (void)checkNewActivity
{
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
    
    [self setObservationsToSyncCount:0];
}

- (void)reload
{
    [self loadData];
	[self checkEmpty];
    [[self tableView] reloadData];
}

- (void)checkSyncStatus
{
    if (self.navigationController.topViewController != self)
        return;
    
    // this method has the side effect of changing the sync toolbar,
    // which we shouldn't do while syncing.
    if (self.isSyncing) {
        return;
    }
    
    self.observationsToSyncCount = [Observation needingSyncCount] + [Observation deletedRecordCount];
    if (self.observationsToSyncCount == 0) {
        self.observationsToSyncCount = [[NSSet setWithArray:[[ObservationFieldValue needingSync] valueForKey:@"observationID"]] count];
        
    }
    self.observationPhotosToSyncCount = [ObservationPhoto needingSyncCount] + [ObservationPhoto deletedRecordCount];
    NSMutableString *msg = [NSMutableString stringWithString:NSLocalizedString(@"Upload ", nil)];
    if (self.observationsToSyncCount > 0) {
        if (self.observationsToSyncCount == 1) {
            [msg appendString:[NSString stringWithFormat:NSLocalizedString(@"%d observation",nil), self.observationsToSyncCount]];
        } else {
            [msg appendString:[NSString stringWithFormat:NSLocalizedString(@"%d observations",nil), self.observationsToSyncCount]];
        }
    }
    if (self.observationPhotosToSyncCount > 0) {
        if (self.observationsToSyncCount > 0) {
            [msg appendString:@", "];
        }
        if (self.observationPhotosToSyncCount == 1) {
            [msg appendString:[NSString stringWithFormat:NSLocalizedString(@"%d photo",nil), self.observationPhotosToSyncCount]];
        } else {
            [msg appendString:[NSString stringWithFormat:NSLocalizedString(@"%d photos",nil), self.observationPhotosToSyncCount]];
        }
    }
    [self.syncButton setTitle:msg];
    
    if (self.itemsToSyncCount > 0) {
        [self.navigationController setToolbarHidden:NO];
        [self setToolbarItems:self.syncToolbarItems animated:YES];
    } else {
        [self.navigationController setToolbarHidden:YES];
        [self setToolbarItems:nil animated:YES];
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

- (NSInteger)itemsToSyncCount
{
    if (!self.observationsToSyncCount) self.observationsToSyncCount = 0;
    if (!self.observationPhotosToSyncCount) self.observationPhotosToSyncCount = 0;
    return self.observationsToSyncCount + self.observationPhotosToSyncCount;
}

- (void)handleNSManagedObjectContextDidSaveNotification:(NSNotification *)notification
{
    if (self.view && ![[UIApplication sharedApplication] isIdleTimerDisabled]) {
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
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ObservationTableCell"];
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:ObservationCellImageTag];
    UILabel *title = (UILabel *)[cell viewWithTag:ObservationCellTitleTag];
    UILabel *subtitle = (UILabel *)[cell viewWithTag:ObservationCellSubTitleTag];
    UILabel *upperRight = (UILabel *)[cell viewWithTag:ObservationCellUpperRightTag];
    UIImageView *syncImage = (UIImageView *)[cell viewWithTag:ObservationCellLowerRightTag];
	UIButton *activityButton = (UIButton *)[cell viewWithTag:ObservationCellActivityButtonTag];
    UIButton *interactiveActivityButton = (UIButton *)[cell viewWithTag:ObservationCellActivityInteractiveButtonTag];
    if (o.sortedObservationPhotos.count > 0) {
        ObservationPhoto *op = [o.sortedObservationPhotos objectAtIndex:0];
		if (op.photoKey == nil) {
            [imageView sd_setImageWithURL:[NSURL URLWithString:op.squareURL]];
		} else {
			imageView.image = [[ImageStore sharedImageStore] find:op.photoKey forSize:ImageStoreSquareSize];
            
            // if we can't find a square image...
            if (!imageView.image) {
                // ...try again a few times, it's probably a new image in the process of being cut-down
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if ([[tableView indexPathsForVisibleRows] containsObject:indexPath]) {
                        [tableView reloadRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationNone];
                    }
                });
            }
		}
        
    } else {
        imageView.image = [[ImageStore sharedImageStore] iconicTaxonImageForName:o.iconicTaxonName];
    }
    
    if (o.speciesGuess && o.speciesGuess.length > 0) {
        [title setText:o.speciesGuess];
    } else {
        [title setText:NSLocalizedString(@"Something...",nil)];
    }
    
    if (o.placeGuess && o.placeGuess.length > 0) {
        subtitle.text = o.placeGuess;
    } else if (o.latitude) {
        subtitle.text = [NSString stringWithFormat:@"%@, %@", o.latitude, o.longitude];
    } else {
        subtitle.text = NSLocalizedString(@"Somewhere...",nil);
    }
    
	if (o.hasUnviewedActivity.boolValue) {
		// make bubble red
		[activityButton setBackgroundImage:[UIImage imageNamed:@"08-chat-red"] forState:UIControlStateNormal];
	} else {
		// make bubble grey
		[activityButton setBackgroundImage:[UIImage imageNamed:@"08-chat"] forState:UIControlStateNormal];
	}
	
	[activityButton setTitle:[NSString stringWithFormat:@"%ld", (long)o.activityCount] forState:UIControlStateNormal];
	
	if (o.activityCount > 0) {
		activityButton.hidden = NO;
        interactiveActivityButton.hidden = NO;
		CGRect frame = syncImage.frame;
		frame.origin.x = cell.frame.size.width - 10 - activityButton.frame.size.width - frame.size.width;
		syncImage.frame = frame;
	} else {
		activityButton.hidden = YES;
        interactiveActivityButton.hidden = YES;
		CGRect frame = syncImage.frame;
		frame.origin.x = cell.frame.size.width - 10 - frame.size.width;
		syncImage.frame = frame;
	}
    [interactiveActivityButton addTarget:self
                                  action:@selector(clickedActivity:event:)
                        forControlEvents:UIControlEventTouchUpInside];
	
    upperRight.text = o.observedOnShortString;
    syncImage.hidden = !o.needsSync;
    
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
        MeHeaderView *header = [[MeHeaderView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 100.0f)];
        
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
            [self configureHeaderView:header forUser:me];
        }
        
        return header;
        
    } else {
        AnonHeaderView *header = [[AnonHeaderView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 100.0f)];
        header.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        
        [header.signupButton setTitle:NSLocalizedString(@"Sign up", @"Title for button that allows users to sign up for a new iNat account")
                             forState:UIControlStateNormal];
        [header.signupButton bk_addEventHandler:^(id sender) {
            
            [[Analytics sharedClient] event:kAnalyticsEventNavigateSignup
                             withProperties:@{ @"from": @"AnonMeHeader" }];
            
            [self presentSignupSplashWithReason:nil];
            
        } forControlEvents:UIControlEventTouchUpInside];
        
        NSString *loginString = NSLocalizedString(@"Already have an account?", @"Title for button that allows users to login to their iNat account");
        NSString *loginStringHighlight = NSLocalizedString(@"account", @"Portion of Already have an account? that should be highlighted.");
        NSMutableAttributedString *loginAttrString = [[NSMutableAttributedString alloc] initWithString:loginString];
        if ([loginString rangeOfString:loginStringHighlight].location != NSNotFound) {
            [loginAttrString addAttribute:NSForegroundColorAttributeName
                                    value:[UIColor blueColor]
                                    range:[loginString rangeOfString:loginStringHighlight]];
        }
        [header.loginButton setAttributedTitle:loginAttrString forState:UIControlStateNormal];
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

#pragma mark - Header helpers

- (void)configureHeaderView:(MeHeaderView *)view forUser:(User *)user {
    
    // icon
    if (user.mediumUserIconURL && ![user.mediumUserIconURL isEqualToString:@""])
        [view.iconImageView sd_setImageWithURL:[NSURL URLWithString:user.mediumUserIconURL]];
    else if (user.userIconURL && ![user.userIconURL isEqualToString:@""])
        [view.iconImageView sd_setImageWithURL:[NSURL URLWithString:user.userIconURL]];
    else {
        FAKIcon *person = [FAKIonIcons iosPersonIconWithSize:80.0f];
        [person addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor]];
        [view.iconImageView setImage:[person imageWithSize:CGSizeMake(80, 80)]];
    }
    
    // name
    if (user.name && ![user.name isEqualToString:@""]) {
        view.nameLabel.text = user.name;
    }
    
    // observation count
    if (user.observationsCount) {
        view.obsCountLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d observations", @"Count of observations by this user."),
                                   user.observationsCount.integerValue];
    }
    
    // identification count
    if (user.identifications) {
        view.idsCountLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%d identifications", @"Count of identifications by this user."),
                                   user.identificationsCount.integerValue];
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
            [meOutline addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
            [meOutline imageWithSize:CGSizeMake(34, 45)];
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
    
    // NSFetchedResultsController request for my observations
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Observation"];
    
    // sort by common name, if available
    request.sortDescriptors = @[ [[NSSortDescriptor alloc] initWithKey:@"sortable" ascending:NO] ];
    
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
    
    self.navigationController.navigationBar.translucent = NO;
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor inatTint];
    
	NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:INatUsernamePrefKey];
	if (username.length) {
		RefreshControl *refresh = [[RefreshControl alloc] init];
		refresh.attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"Pull to Refresh", nil)];
		[refresh addTarget:self action:@selector(pullToRefresh) forControlEvents:UIControlEventValueChanged];
		self.refreshControl = refresh;
	} else {
		self.refreshControl = nil;
	}
    
    [self reload];
    
    // observation detail view controller has a different toolbar tint color
    [[[self navigationController] toolbar] setBarTintColor:[UIColor inatTint]];
    [[[self navigationController] toolbar] setTintColor:[UIColor whiteColor]];
    self.syncButton.tintColor = [UIColor whiteColor];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self setSyncToolbarItems:[NSArray arrayWithObjects:
                               [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                               self.syncButton, 
                               [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil],
                               nil]];
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
        (!self.lastRefreshAt || [self.lastRefreshAt timeIntervalSinceNow] < -1*seconds) &&
        self.itemsToSyncCount == 0) {
        [self refreshRequestedNotify:NO];
        [self checkForDeleted];
        [self checkNewActivity];
        
    }
    
    [self loadUserForHeader];

    [[Analytics sharedClient] timedEvent:kAnalyticsEventNavigateObservations];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [self stopSync];
    [self stopEditing];
    [self setToolbarItems:nil animated:YES];
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
    if ([[segue identifier] isEqualToString:@"AddObservationSegue"]) {
        ObservationDetailViewController *vc = [segue destinationViewController];
        [vc setDelegate:self];
        Observation *o = [Observation object];
        o.localObservedOn = [NSDate date];
        o.observedOnString = [Observation.jsDateFormatter stringFromDate:o.localObservedOn];
        [vc setObservation:o];
    } else if ([segue.identifier isEqualToString:@"EditObservationSegue"]) {
        ObservationDetailViewController *ovc = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil] instantiateViewControllerWithIdentifier:@"ObservationDetailViewController"];
        ObservationPageViewController *pvc = [segue destinationViewController];
        [ovc setDelegate:self];
        Observation *o = [fetchedResultsController objectAtIndexPath:[self.tableView indexPathForSelectedRow]];
        [ovc setObservation:o];
        [pvc setViewControllers:[NSArray arrayWithObject:ovc]
                       direction:UIPageViewControllerNavigationDirectionForward
                        animated:YES
                      completion:nil];
    }
}

#pragma mark - RKObjectLoaderDelegate
- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects
{
    if ([objectLoader.URL.absoluteString containsString:@"/people/"]) {
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

    if ([objectLoader.URL.absoluteString containsString:@"/people/"]) {
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

    [SVProgressHUD dismiss];
    
    [self stopSync];
    NSString *reasonMsg = NSLocalizedString(@"You must be logged in to upload to iNaturalist.org.",
                                            @"This is an explanation for why the sync button triggers a login prompt.");
    [self presentSignupSplashWithReason:reasonMsg];
}

- (void)uploadSessionFinished {
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];

    [self stopSync];
    self.tableView.userInteractionEnabled = YES;
    self.tabBarController.tabBar.userInteractionEnabled = YES;
    self.navigationController.navigationBar.userInteractionEnabled = YES;
    
    if (self.nonFatalUploadErrors && self.nonFatalUploadErrors.count > 0) {
        [SVProgressHUD dismiss];
        
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Heads up",nil)
                                                     message:[self.nonFatalUploadErrors componentsJoinedByString:@"\n\n"]
                                                    delegate:self
                                           cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                           otherButtonTitles:nil];
        [av show];
        
        [self.nonFatalUploadErrors removeAllObjects];
    } else {
        [SVProgressHUD showSuccessWithStatus:nil];
        // re-enable user interaction with the tableview
    }
    
    // make sure any deleted records get gone
    NSError *error = nil;
    [[[RKObjectManager sharedManager] objectStore] save:&error];
    
    [self loadUserForHeader];
}

- (void)uploadStartedFor:(Observation *)observation {
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];

    NSString *name = observation.taxon.name ?: observation.speciesGuess;
    if (!name) {
        name = NSLocalizedString(@"something", @"Something observed by the user.");
    }
    
    NSString *activityMsg = [NSString stringWithFormat:NSLocalizedString(@"Uploading '%@'...", @"in-progress upload message"), name];
    [SVProgressHUD showWithStatus:activityMsg maskType:SVProgressHUDMaskTypeNone];
}

- (void)uploadSuccessFor:(Observation *)observation {
    NSString *name = observation.taxon.name ?: observation.speciesGuess;
    if (!name) {
        name = NSLocalizedString(@"something", @"Something observed by the user.");
    }

    NSString *activityMsg = [NSString stringWithFormat:NSLocalizedString(@"Finished with '%@'...", @"in-progress upload message"), name];
    [SVProgressHUD showSuccessWithStatus:activityMsg maskType:SVProgressHUDMaskTypeNone];
    NSError *error = nil;
    [fetchedResultsController performFetch:&error];
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
        
        [SVProgressHUD dismiss];
        
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
    
    NSString *statusMsg = [NSString stringWithFormat:NSLocalizedString(@"Deleting %@", @"in-progress delete message"),
                           deletedRecord.modelName.humanize];
    [SVProgressHUD showWithStatus:statusMsg];
}

- (void)deleteSuccessFor:(DeletedRecord *)deletedRecord {
    NSString *statusMsg = [NSString stringWithFormat:NSLocalizedString(@"Deleted %@", @"finished delete message"),
                           deletedRecord.modelName.humanize];
    [SVProgressHUD showSuccessWithStatus:statusMsg];
}

- (void)deleteSessionFinished {
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    
    [SVProgressHUD dismiss];
}

- (void)deleteFailedFor:(DeletedRecord *)deletedRecord error:(NSError *)error {
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];

    [SVProgressHUD dismiss];
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
