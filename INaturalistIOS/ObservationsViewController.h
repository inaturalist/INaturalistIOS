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

@property (nonatomic, strong) NSDate *lastRefreshAt;

- (IBAction)sync:(id)sender;
- (IBAction)viewActivity:(id)sender;
- (void)stopSync;

- (void)syncObservationPhoto:(ObservationPhoto *)op;
- (void)loadData;
- (void)reload;
- (void)checkSyncStatus;
- (void)clickedActivity:(id)sender event:(UIEvent *)event;
- (void)handleNSManagedObjectContextDidSaveNotification:(NSNotification *)notification;
- (BOOL)isSyncing;
- (void)refreshData;

@end
