//
//  ProjectDetailViewController.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/14/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Three20/Three20.h>
#import "ObservationDetailViewController.h"

@class Project;

@interface ProjectDetailViewController : UITableViewController <RKObjectLoaderDelegate, ObservationDetailViewControllerDelegate>

@property (nonatomic, strong) Project *project;
@property (nonatomic, strong) NSMutableArray *listedTaxa;
@property (weak, nonatomic) IBOutlet TTImageView *projectIcon;
@property (weak, nonatomic) IBOutlet UILabel *projectTitle;
@property (weak, nonatomic) IBOutlet TTStyledTextLabel *projectSubtitle;
@property (nonatomic, strong) RKObjectLoader *loader;
@property (nonatomic, strong) NSDate *lastSyncedAt;

- (IBAction)clickedSync:(id)sender;
- (void)clickedAdd:(id)sender event:(UIEvent *)event;
- (void)sync;
- (void)stopSync;
- (void)loadData;
@end
