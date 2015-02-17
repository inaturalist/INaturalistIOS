//
//  ObservationsViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/13/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <SVProgressHUD/SVProgressHUD.h>
#import <AFNetworking/UIImageView+AFNetworking.h>
#import <BlocksKit/BlocksKit.h>
#import <FontAwesomeKit/FAKIonIcons.h>

#import "ObservationsViewController.h"
#import "LoginViewController.h"
#import "Observation.h"
#import "ObservationFieldValue.h"
#import "ObservationPageViewController.h"
#import "ObservationPhoto.h"
#import "ProjectObservation.h"
#import "Project.h"
#import "ImageStore.h"
#import "INatUITabBarController.h"
#import "INaturalistAppDelegate.h"
#import "TutorialViewController.h"
#import "RefreshControl.h"
#import "ObservationActivityViewController.h"
#import "UIImageView+WebCache.h"
#import "UIColor+INaturalist.h"
#import "CustomIOS7AlertView.h"
#import "Analytics.h"
#import "TutorialSinglePageViewController.h"
#import "User.h"
#import "SettingsViewController.h"


static const int ObservationCellImageTag = 5;
static const int ObservationCellTitleTag = 1;
static const int ObservationCellSubTitleTag = 2;
static const int ObservationCellUpperRightTag = 3;
static const int ObservationCellLowerRightTag = 4;
static const int ObservationCellActivityButtonTag = 6;
static const int ObservationCellActivityInteractiveButtonTag = 7;

@interface ObservationsViewController () <NSFetchedResultsControllerDelegate,UINavigationControllerDelegate> {
    NSFetchedResultsController *fetchedResultsController;
}
@end

@implementation ObservationsViewController
@synthesize syncButton = _syncButton;
@synthesize observationsToSyncCount = _observationsToSyncCount;
@synthesize observationPhotosToSyncCount = _observationPhotosToSyncCount;
@synthesize syncToolbarItems = _syncToolbarItems;
@synthesize syncedObservationsCount = _syncedObservationsCount;
@synthesize syncedObservationPhotosCount = _syncedObservationPhotosCount;
@synthesize stopSyncButton = _stopSyncButton;
@synthesize noContentLabel = _noContentLabel;
@synthesize syncQueue = _syncQueue;
@synthesize syncErrors = _syncErrors;
@synthesize lastRefreshAt = _lastRefreshAt;

- (IBAction)sync:(id)sender {
    if (self.isSyncing) {
        return;
    }
    
    if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Internet connection required",nil)
                                                     message:NSLocalizedString(@"You must be connected to the Internet to sync with iNaturalist.org",nil)
                                                    delegate:self 
                                           cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                           otherButtonTitles:nil];
        [av show];
        return;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:INatTokenPrefKey]) {
        [self performSegueWithIdentifier:@"LoginSegue" sender:nil];
        return;
    }
    
    if (!self.stopSyncButton) {
        self.stopSyncButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Stop sync",nil)
                                                               style:UIBarButtonItemStyleBordered 
                                                              target:self 
                                                              action:@selector(stopSync)];
        self.stopSyncButton.tintColor = [UIColor redColor];
    }
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [self.navigationController setToolbarHidden:NO];
    [self setToolbarItems:[NSArray arrayWithObjects:flex, self.stopSyncButton, flex, nil] 
                 animated:YES];
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Syncing...",nil) maskType:SVProgressHUDMaskTypeNone];
    
    [[Analytics sharedClient] event:kAnalyticsEventSyncObservation];

    if (!self.syncQueue) {
        self.syncQueue = [[SyncQueue alloc] initWithDelegate:self];
    }
	[self.syncQueue.queue removeAllObjects];
	[self.syncQueue addModel:Observation.class];
	[self.syncQueue addModel:ObservationFieldValue.class];
	[self.syncQueue addModel:ProjectObservation.class];
    if ([ObservationPhoto needingSyncCount] > 0) {
        for (ObservationPhoto *op in [ObservationPhoto needingSync]) {
            // check to see if for some reason a LocalPhoto was created without files. If so, destroy it and move on.
            NSString *path = [[ImageStore sharedImageStore] pathForKey:op.photoKey forSize:ImageStoreSmallSize];
            if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
                [op destroy];
            }
        }
        [[[RKObjectManager sharedManager] objectStore] save:nil];
    }
	[self.syncQueue addModel:ObservationPhoto.class syncSelector:@selector(syncObservationPhoto:)];
	[self.syncQueue start];
    
    // temporarily disable user interaction with the tableview
    self.tableView.userInteractionEnabled = NO;
}

- (void)stopSync
{
    [SVProgressHUD dismiss];
    // re-enable user interaction with the tableview
    self.tableView.userInteractionEnabled = YES;
    if (self.syncQueue) {
        [self.syncQueue stop];
    }
    [[self tableView] reloadData];
    self.tableView.scrollEnabled = YES;
    [self checkSyncStatus];
}

- (BOOL)isSyncing
{
    return [UIApplication sharedApplication].isIdleTimerDisabled;
}

- (void)syncObservationPhoto:(ObservationPhoto *)op
{
    INaturalistAppDelegate *app = [[UIApplication sharedApplication] delegate];
    [app.photoObjectManager.client setAuthenticationType: RKRequestAuthenticationTypeNone];//RKRequestAuthenticationTypeHTTPBasic;
    // in theory no observation photo should be without an observation, but...
    if (!op.observation) {
        [op destroy];
        return;
    }
    void (^prepareObservationPhoto)(RKObjectLoader *) = ^(RKObjectLoader *loader) {
        loader.delegate = self.syncQueue;
        RKObjectMapping* serializationMapping = [app.photoObjectManager.mappingProvider 
                                                 serializationMappingForClass:[ObservationPhoto class]];
        NSError* error = nil;
        NSDictionary* dictionary = [[RKObjectSerializer serializerWithObject:op mapping:serializationMapping] 
                                    serializedObject:&error];
        RKParams* params = [RKParams paramsWithDictionary:dictionary];
        NSInteger imageSize = [[[RKClient sharedClient] reachabilityObserver] isReachableViaWiFi] ? ImageStoreLargeSize : ImageStoreSmallSize;
        
        [params setFile:[[ImageStore sharedImageStore] pathForKey:op.photoKey 
                                                          forSize:imageSize]
               forParam:@"file"];
        loader.params = params;
        loader.objectMapping = [ObservationPhoto mapping];
    };
    if (op.syncedAt && op.recordID) {
        [app.photoObjectManager putObject:op usingBlock:prepareObservationPhoto];
    } else {
        [app.photoObjectManager postObject:op usingBlock:prepareObservationPhoto];
    }
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
		[[RKObjectManager sharedManager] loadObjectsAtResourcePath:[NSString stringWithFormat:@"/observations/%@.json?extra=observation_photos,projects,fields", username]
													 objectMapping:[Observation mapping]
														  delegate:self];
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

- (void)loadData
{
    NSError *fetchError;
    [fetchedResultsController performFetch:&fetchError];
    if (fetchError) {
        [SVProgressHUD showErrorWithStatus:fetchError.localizedDescription];
    }
    [self setObservationsToSyncCount:0];
}

- (void)reload
{
    [self loadData];
	[self checkEmpty];
}

- (void)checkSyncStatus
{
    self.observationsToSyncCount = [Observation needingSyncCount] + [Observation deletedRecordCount];
    if (self.observationsToSyncCount == 0) {
        self.observationsToSyncCount = [[NSSet setWithArray:[[ObservationFieldValue needingSync] valueForKey:@"observationID"]] count];
        
    }
    self.observationPhotosToSyncCount = [ObservationPhoto needingSyncCount] + [ObservationPhoto deletedRecordCount];
    NSMutableString *msg = [NSMutableString stringWithString:NSLocalizedString(@"Sync ",nil)];
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
    self.syncedObservationsCount = 0;
}

- (void)checkEmpty {
    id <NSFetchedResultsSectionInfo> sectionInfo = [fetchedResultsController sections][0];
    if ([sectionInfo numberOfObjects] == 0) {
        if (!self.noContentLabel) {
            self.noContentLabel = [[UILabel alloc] init];
            self.noContentLabel.text = NSLocalizedString(@"You don't have any observations yet.",nil);
            self.noContentLabel.backgroundColor = [UIColor clearColor];
            self.noContentLabel.textColor = [UIColor grayColor];
            self.noContentLabel.numberOfLines = 0;
            [self.noContentLabel sizeToFit];
            self.noContentLabel.textAlignment = NSTextAlignmentCenter;
            self.noContentLabel.center = CGPointMake(self.view.center.x, 
                                                     self.tableView.rowHeight * 2 + (self.tableView.rowHeight / 2));
            self.noContentLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        }
        [self.view addSubview:self.noContentLabel];
    } else if (self.noContentLabel) {
        [self.noContentLabel removeFromSuperview];
    }
}

- (int)itemsToSyncCount
{
    if (!self.observationsToSyncCount) self.observationsToSyncCount = 0;
    if (!self.observationPhotosToSyncCount) self.observationPhotosToSyncCount = 0;
    return self.observationsToSyncCount + self.observationPhotosToSyncCount;
}

- (void)handleNSManagedObjectContextDidSaveNotification:(NSNotification *)notification {
    if (self.view && ![[UIApplication sharedApplication] isIdleTimerDisabled]) {
        [self reload];
    }
}

- (BOOL)autoLaunchTutorial
{
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    
    if ([settings objectForKey:kDefaultsKeyOldTutorialSeen]) {
        return NO;
    }
        
    if ([settings boolForKey:kDefaultsKeyTutorialNeverAgain]) {
        return NO;
    }
    
    if ([settings boolForKey:kDefaultsKeyTutorialSeenNewObs]) {
        if ([settings boolForKey:kDefaultsKeyTutorialSeenNewObsCommunity]) {
            return NO;
        } else {
            [self showTutorialImage:[UIImage imageNamed:@"tutorial4en.png"]
                              title:NSLocalizedString(@"Connect With Other Nature Lovers", @"Title for community tutorial screen")];
            [settings setBool:YES forKey:kDefaultsKeyTutorialSeenNewObsCommunity];
            [settings synchronize];
            return YES;
        }
    } else {
        [self showTutorialImage:[UIImage imageNamed:@"tutorial2en.png"]
                          title:NSLocalizedString(@"Record What You See", @"Title for new observation tutorial screen")];
        [settings setBool:YES forKey:kDefaultsKeyTutorialSeenNewObs];
        [settings synchronize];
        return YES;
    }
}

- (void)showTutorialImage:(UIImage *)image title:(NSString *)title {
    TutorialSinglePageViewController *vc = [[TutorialSinglePageViewController alloc] initWithNibName:nil bundle:nil];
    vc.tutorialImage = image;
    vc.tutorialTitle = title;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self presentViewController:vc animated:YES completion:nil];
    });

}

- (BOOL)autoLaunchSignIn
{
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    if ([settings objectForKey:@"firstSignInSeen"]) {
        return NO;
    }
    LoginViewController *vc = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil]
                               instantiateViewControllerWithIdentifier:@"LoginViewController"];
    UINavigationController *modalNavController = [[UINavigationController alloc]
                                                  initWithRootViewController:vc];
    [self presentViewController:modalNavController animated:YES completion:nil];
    [settings setObject:[NSNumber numberWithBool:YES] forKey:@"firstSignInSeen"];
    [settings synchronize];
    return YES;
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
    CustomIOS7AlertView *alertView = [[CustomIOS7AlertView alloc] init];
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
        [alertView setOnButtonTouchUpInside:^(CustomIOS7AlertView *alertView, int buttonIndex) {
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
		[activityButton setBackgroundImage:[UIImage imageNamed:@"08-chat-red.png"] forState:UIControlStateNormal];
	} else {
		// make bubble grey
		[activityButton setBackgroundImage:[UIImage imageNamed:@"08-chat.png"] forState:UIControlStateNormal];
	}
	
	[activityButton setTitle:[NSString stringWithFormat:@"%d", o.activityCount] forState:UIControlStateNormal];
	
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

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
		
		// RWTODO: delete from server
		
        Observation *o = [fetchedResultsController objectAtIndexPath:indexPath];
        [o destroy];
        NSError *fetchError;
        [fetchedResultsController performFetch:&fetchError];
        if (fetchError) {
            [SVProgressHUD showErrorWithStatus:fetchError.localizedDescription];
        }
        
        [(INatUITabBarController *)self.tabBarController setObservationsTabBadge];
        if (!self.isEditing) {
            [self checkSyncStatus];
        }
        id <NSFetchedResultsSectionInfo> sectionInfo = [fetchedResultsController sections][0];
        if ([sectionInfo numberOfObjects] == 0) {
            [self stopEditing];
        }
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 100)];
    header.backgroundColor = [UIColor whiteColor];
    
    UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(20, 10, 80, 80)];
    iv.layer.cornerRadius = 40.0f;
    iv.layer.borderColor = [UIColor grayColor].CGColor;
    iv.layer.borderWidth = 0.5f;
    iv.clipsToBounds = YES;
    [header addSubview:iv];
    
    UILabel *userRealNameLabel = [[UILabel alloc] initWithFrame:CGRectMake(110, 10, tableView.frame.size.width - 130, 20)];
    userRealNameLabel.textAlignment = NSTextAlignmentCenter;
    userRealNameLabel.font = [UIFont systemFontOfSize:14.0f];
    userRealNameLabel.textColor = [UIColor grayColor];
    [header addSubview:userRealNameLabel];
    
    UILabel *obsCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(110, 45, tableView.frame.size.width - 130, 10)];
    obsCountLabel.textAlignment = NSTextAlignmentCenter;
    obsCountLabel.font = [UIFont systemFontOfSize:11.0f];
    obsCountLabel.textColor = [UIColor grayColor];
    [header addSubview:obsCountLabel];

    UILabel *taxaCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(110, 60, tableView.frame.size.width - 130, 10)];
    taxaCountLabel.textAlignment = NSTextAlignmentCenter;
    taxaCountLabel.font = [UIFont systemFontOfSize:11.0f];
    taxaCountLabel.textColor = [UIColor grayColor];
    [header addSubview:taxaCountLabel];

    UILabel *idCountLabel = [[UILabel alloc] initWithFrame:CGRectMake(110, 75, tableView.frame.size.width - 130, 10)];
    idCountLabel.textAlignment = NSTextAlignmentCenter;
    idCountLabel.font = [UIFont systemFontOfSize:11.0f];
    idCountLabel.textColor = [UIColor grayColor];
    [header addSubview:idCountLabel];
    
    NSString *username = [[NSUserDefaults standardUserDefaults] stringForKey:INatUsernamePrefKey];
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:@"User"];
    fetch.predicate = [NSPredicate predicateWithFormat:@"login == %@", username];
    fetch.sortDescriptors = @[ [[NSSortDescriptor alloc] initWithKey:@"login" ascending:YES] ];
    
    NSError *fetchError;
    NSArray *users = [[Observation managedObjectContext] executeFetchRequest:fetch error:&fetchError];
    if (fetchError) {
        [SVProgressHUD showErrorWithStatus:fetchError.localizedDescription];
    }
    if (users.count == 0) {
        // need to fetch from server
    } else if (users.count == 1) {
        User *me = users.firstObject;
        
        self.title = me.login;
        self.navigationController.tabBarItem.title = @"Me";
        
        if (me.userIconURL && ![me.userIconURL isEqualToString:@""])
            [iv sd_setImageWithURL:[NSURL URLWithString:[me.userIconURL stringByReplacingOccurrencesOfString:@"thumb" withString:@"medium"]]];
        
        if (me.name && ![me.name isEqualToString:@""])
            userRealNameLabel.text = me.name;
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.inaturalist.org/users/%@.json", username]];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [NSURLConnection sendAsynchronousRequest:request
                                           queue:[NSOperationQueue mainQueue]
                               completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                                   NSLog(@"completion is %@", response);
                                   if (connectionError) {
                                       [SVProgressHUD showErrorWithStatus:connectionError.localizedDescription];
                                       return;
                                   }
                                   NSError *jsonError;
                                   NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data
                                                                                        options:nil
                                                                                          error:&jsonError];
                                   
                                   if (jsonError) {
                                       [SVProgressHUD showErrorWithStatus:jsonError.localizedDescription];
                                   }
                                   NSNumber *obsCount = [dict objectForKey:@"observations_count"];
                                   NSNumber *idCount = [dict objectForKey:@"identifications_count"];
                                   NSNumber *taxaCount = [dict objectForKey:@"life_list_taxa_count"];
                                   
                                   obsCountLabel.text = [NSString stringWithFormat:@"Observations: %ld", (long)obsCount.integerValue];
                                   idCountLabel.text = [NSString stringWithFormat:@"Identifications: %ld", (long)idCount.integerValue];
                                   taxaCountLabel.text = [NSString stringWithFormat:@"Distinct: %ld", (long)taxaCount.integerValue];
                               }];
        
        
    } else {
        [SVProgressHUD showErrorWithStatus:@"Got too many users"];
    }
    
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 100.0f;
}

# pragma mark memory management
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark uibarbutton targets

- (void)settings {
    UIStoryboard *mainStoryboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    SettingsViewController *settings = [mainStoryboard instantiateViewControllerWithIdentifier:@"settings"];
    [self.navigationController pushViewController:settings animated:YES];
}

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];

    FAKIcon *settings = [FAKIonIcons ios7GearOutlineIconWithSize:32.0f];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[settings imageWithSize:CGSizeMake(32, 32)]
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(settings)];
//    // if you need to test syncing lots of obs
//    [Observation deleteAll];
//    for (int i = 0; i < 50; i++) {
//        [self.observations addObject:[Observation stub]];
//    }
//    [[[RKObjectManager sharedManager] objectStore] save];
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Observation"];
    fetchRequest.sortDescriptors = @[ [[NSSortDescriptor alloc] initWithKey:@"sortable"
                                                                  ascending:NO] ];
    fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                   managedObjectContext:[Observation managedObjectContext]
                                                                     sectionNameKeyPath:nil
                                                                              cacheName:nil];
    fetchedResultsController.delegate = self;
    
    NSString *login = [[NSUserDefaults standardUserDefaults] stringForKey:INatUsernamePrefKey];
    if (login) {
        NSFetchRequest *userFetch = [NSFetchRequest fetchRequestWithEntityName:@"User"];
        userFetch.predicate = [NSPredicate predicateWithFormat:@"login == %@", login];
        userFetch.sortDescriptors = @[ [[NSSortDescriptor alloc] initWithKey:@"login" ascending:YES] ];
        NSError *fetchError;
        NSArray *users = [[Observation managedObjectContext] executeFetchRequest:userFetch error:&fetchError];
        if (users.count == 0) {
            // need to fetch from server
            NSLog(@"didn't find local user");
            [[RKObjectManager sharedManager] loadObjectsAtResourcePath:[NSString stringWithFormat:@"/users/%@.json", login]
                                                            usingBlock:^(RKObjectLoader *loader) {
                                                                loader.objectMapping = [User mapping];
                                                                
                                                                loader.onDidLoadObjects = ^(NSArray *objects) {
                                                                    NSError *saveError;
                                                                    [[[RKObjectManager sharedManager] objectStore] save:&saveError];
                                                                    if (saveError) {
                                                                        [SVProgressHUD showErrorWithStatus:saveError.localizedDescription];
                                                                    } else {
                                                                        NSError *fetchError;
                                                                        NSArray *users = [[Observation managedObjectContext] executeFetchRequest:userFetch
                                                                                                                                           error:&fetchError];
                                                                        if (fetchError) {
                                                                            [SVProgressHUD showErrorWithStatus:fetchError.localizedDescription];
                                                                        } else {
                                                                            User *user = [users firstObject];

                                                                            fetchRequest.predicate = [NSPredicate predicateWithFormat:@"userID == %ld",
                                                                                                      (long)user.recordID.integerValue];
                                                                            [fetchedResultsController performFetch:&fetchError];
                                                                            if (fetchError) {
                                                                                [SVProgressHUD showErrorWithStatus:fetchError.localizedDescription];
                                                                            }
                                                                        }
                                                                    }
                                                                };
                                                                
                                                                loader.onDidFailLoadWithError = ^(NSError *error) {
                                                                    [SVProgressHUD showErrorWithStatus:error.localizedDescription];
                                                                };
                                                            }];
        } else {
            User *user = [users firstObject];
            //fetchRequest.predicate = [NSPredicate predicateWithFormat:@"userID == %ld",
            //                          (long)user.recordID.integerValue];
            NSError *fetchError;
            [fetchedResultsController performFetch:&fetchError];
            if (fetchError) {
                [SVProgressHUD showErrorWithStatus:fetchError.localizedDescription];
            }
        }
    } else {
        // not logged in, so any fetch request is good as is
        // any observations belong to the user
        NSError *fetchError;
        [fetchedResultsController performFetch:&fetchError];
        if (fetchError) {
            [SVProgressHUD showErrorWithStatus:fetchError.localizedDescription];
        }
    }
    
    self.title = NSLocalizedString(@"Observations", nil);
    
    FAKIcon *personOutline = [FAKIonIcons ios7PersonOutlineIconWithSize:35];
    self.navigationController.tabBarItem.image = [personOutline imageWithSize:CGSizeMake(34,45)];
    
    FAKIcon *person = [FAKIonIcons ios7PersonIconWithSize:35];
    self.navigationController.tabBarItem.selectedImage = [person imageWithSize:CGSizeMake(34,45)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNSManagedObjectContextDidSaveNotification:)
                                                 name:NSManagedObjectContextDidSaveNotification 
                                               object:[Observation managedObjectContext]];
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
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
    if ([self autoLaunchTutorial]) {
        // rad
    } else if (![self autoLaunchSignIn]) {
        [self autoLaunchNewFeatures];
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
        [self pullToRefresh];
        [self checkForDeleted];
        [self checkNewActivity];
    }
    
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
    } else if ([segue.identifier isEqualToString:@"LoginSegue"]) {
        LoginViewController *vc = (LoginViewController *)[segue.destinationViewController topViewController];
        [vc setDelegate:self];
    }
}

#pragma mark LoginControllerViewDelegate methods
- (void)loginViewControllerDidLogIn:(LoginViewController *)controller
{
    [self sync:nil];
}

#pragma mark - RKObjectLoaderDelegate
- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects
{
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
//    NSLog(@"objectLoader didFailWithError, error: %@", error);
    // was running into a bug in release build config where the object loader was
    // getting deallocated after handling an error.  This is a kludge.
//    self.loader = objectLoader;
    
	
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
		NSLog(@"Received status code %d for %@", response.statusCode, request.resourcePath);
	}
}

- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error
{
	NSLog(@"Request Error: %@", error.localizedDescription);
}

#pragma mark - SyncQueueDelegate
- (void)syncQueueStartedSyncFor:(id)model
{
    NSString *activityMsg;
    if (model == ObservationPhoto.class) {
        activityMsg = NSLocalizedString(@"Syncing photos...",nil);
    } else {
        NSString *modelName = NSStringFromClass(model).humanize.pluralize;
        activityMsg = [NSString stringWithFormat:NSLocalizedString(@"Syncing %@...",nil), NSLocalizedString(modelName, nil)];
    }
    [SVProgressHUD showWithStatus:activityMsg maskType:SVProgressHUDMaskTypeNone];
}
- (void)syncQueueSynced:(INatModel *)record number:(NSInteger)number of:(NSInteger)total
{
    NSString *activityMsg = [NSString stringWithFormat:NSLocalizedString(@"Synced %d of %d %@",nil),
                             number, 
                             total, 
                             NSStringFromClass(record.class).humanize.pluralize];
    [SVProgressHUD showWithStatus:activityMsg maskType:SVProgressHUDMaskTypeNone];
}

- (void)syncQueueFinished
{
    [self stopSync];
    if (self.syncErrors && self.syncErrors.count > 0) {
        [SVProgressHUD dismiss];

        UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Heads up",nil)
                                                     message:[self.syncErrors componentsJoinedByString:@"\n\n"]
                                                    delegate:self 
                                           cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                           otherButtonTitles:nil];
        [av show];
        self.syncErrors = nil;
    } else {
        [SVProgressHUD showSuccessWithStatus:nil];
        // re-enable user interaction with the tableview
        self.tableView.userInteractionEnabled = YES;
    }
    
    // make sure any deleted records get gone
    NSError *error = nil;
    [[[RKObjectManager sharedManager] objectStore] save:&error];
}

- (void)syncQueueAuthRequired
{
    [SVProgressHUD dismiss];
    
    [self stopSync];
    [self performSegueWithIdentifier:@"LoginSegue" sender:nil];
}

- (void)syncQueue:(SyncQueue *)syncQueue objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error
{
    if ([objectLoader.targetObject isKindOfClass:ProjectObservation.class]) {
        ProjectObservation *po = (ProjectObservation *)objectLoader.targetObject;
        if (!self.syncErrors) {
            self.syncErrors = [[NSMutableArray alloc] init];
        }
        [self.syncErrors addObject:[NSString stringWithFormat:NSLocalizedString(@"%@ (%@) couldn't be added to project %@: %@",nil),
                                    po.observation.speciesGuess, 
                                    po.observation.observedOnShortString,
                                    po.project.title,
                                    error.localizedDescription]];
        [po deleteEntity];
    } else if ([objectLoader.targetObject isKindOfClass:ObservationFieldValue.class]) {
        // HACK: not sure where these observationless OFVs are coming from, so I'm just deleting
        // them and hoping for the best. I did add some Flurry logging for ofv creation, though.
        // kueda 20140112
        ObservationFieldValue *ofv = (ObservationFieldValue *)objectLoader.targetObject;
        if (!ofv.observation) {
            NSLog(@"ERROR: deleted mysterious ofv: %@", ofv);
            [ofv deleteEntity];
        }
    } else {
        if ([self isSyncing]) {
            [SVProgressHUD dismiss];
            
            NSString *alertTitle;
            NSString *alertMessage;
            if (error.domain == RKErrorDomain && error.code == RKRequestConnectionTimeoutError) {
                alertTitle = NSLocalizedString(@"Request timed out",nil);
                alertMessage = NSLocalizedString(@"This can happen when your Internet connection is slow or intermittent.  Please try again the next time you're on WiFi.",nil);
            } else {
                alertTitle = NSLocalizedString(@"Whoops!",nil);
                alertMessage = [NSString stringWithFormat:NSLocalizedString(@"Looks like there was an error: %@",nil), error.localizedDescription];
            }
            UIAlertView *av = [[UIAlertView alloc] initWithTitle:alertTitle 
                                                         message:alertMessage
                                                        delegate:self 
                                               cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                               otherButtonTitles:nil];
            [av show];
            [objectLoader cancel];
        } 
        [self stopSync];
    }
}

- (void)syncQueue:(SyncQueue *)syncQueue nonLoaderRequestFailedWithError:(NSError *)error {
    if ([self isSyncing]) {
        [SVProgressHUD dismiss];

        NSString *alertTitle;
        NSString *alertMessage;
        if (error.domain == RKErrorDomain && error.code == RKRequestConnectionTimeoutError) {
            alertTitle = NSLocalizedString(@"Request timed out",nil);
            alertMessage = NSLocalizedString(@"This can happen when your Internet connection is slow or intermittent.  Please try again the next time you're on WiFi.",nil);
        } else {
            alertTitle = NSLocalizedString(@"Whoops!",nil);
            alertMessage = [NSString stringWithFormat:NSLocalizedString(@"Looks like there was an error: %@",nil), error.localizedDescription];
        }
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:alertTitle
                                                     message:alertMessage
                                                    delegate:self
                                           cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                           otherButtonTitles:nil];
        [av show];
    }
    [self stopSync];
}

- (void)syncQueueUnexpectedResponse
{
    [SVProgressHUD dismiss];
    
    [self stopSync];
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Whoops!",nil)
                                                 message:NSLocalizedString(@"There was an unexpected error.",nil)
                                                delegate:self
                                       cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                       otherButtonTitles:nil];
    [av show];
}

#pragma mark - NSFetchedResultsController delegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
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



@end
