//
//  INatObserverViewController.h
//  INatObserver
//
//  Created by Ken-ichi Ueda on 2/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "INObservationFormViewController.h"
#import "LoginViewController.h"

@class Observation;
@class ObservationStore;
@class DejalActivityView;

@interface INatObserverViewController : UITableViewController <INObservationFormViewControllerDelegate, RKObjectLoaderDelegate, LoginViewControllerDelegate, RKRequestQueueDelegate>
{
    DejalActivityView *syncActivityView;
}
@property (nonatomic, strong) NSMutableArray *observations;
@property (nonatomic, assign) int observationsToSyncCount;
@property (nonatomic, assign) int syncedObservationsCount;
@property (nonatomic, strong) NSArray *syncToolbarItems;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *syncLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *syncButton;

- (IBAction)sync:(id)sender;
- (IBAction)edit:(id)sender;

- (void)loadData;
- (void)checkSyncStatus;
@end
