//
//  ObservationsViewController.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/13/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ObservationDetailViewController.h"
#import "UploadManager.h"
#import "DeletedRecord.h"

@class INatModel;
@class Observation;
@class ObservationStore;


@interface ObservationsViewController : UITableViewController <ObservationDetailViewControllerDelegate, UIAlertViewDelegate, RKObjectLoaderDelegate, RKRequestDelegate, RKObjectMapperDelegate>
@property (nonatomic, assign) NSInteger observationsToSyncCount;
@property (nonatomic, assign) NSInteger syncedObservationsCount;
@property (nonatomic, assign) NSInteger observationPhotosToSyncCount;
@property (nonatomic, assign) NSInteger syncedObservationPhotosCount;
@property (nonatomic, strong) NSArray *syncToolbarItems;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *syncButton; // if the button is just kind of floating and not assigned a super view, it will get deallocated UNLESS we have a strong reference here
@property (strong, nonatomic) IBOutlet UIBarButtonItem *editButton;
@property (strong, nonatomic) UIBarButtonItem *stopSyncButton;
@property (nonatomic, strong) NSDate *lastRefreshAt;

- (IBAction)sync:(id)sender;
- (IBAction)viewActivity:(id)sender;
- (void)stopSync;
- (void)stopEditing;

- (void)syncObservationPhoto:(ObservationPhoto *)op;
- (void)loadData;
- (void)reload;
- (void)checkSyncStatus;
- (NSInteger)itemsToSyncCount;
- (void)clickedActivity:(id)sender event:(UIEvent *)event;
- (void)handleNSManagedObjectContextDidSaveNotification:(NSNotification *)notification;
- (BOOL)isSyncing;
- (void)refreshData;

@end
