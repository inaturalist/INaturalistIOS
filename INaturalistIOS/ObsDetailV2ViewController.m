//
//  ObsDetailV2ViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/17/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import "ObsDetailV2ViewController.h"
#import "Observation.h"
#import "ObsDetailViewModel.h"
#import "DisclosureCell.h"
#import "SubtitleDisclosureCell.h"
#import "ObsDetailActivityViewModel.h"
#import "ObsDetailInfoViewModel.h"
#import "ObsDetailFavesViewModel.h"
#import "Analytics.h"
#import "AddCommentViewController.h"
#import "AddIdentificationViewController.h"
#import "ProjectObservationsViewController.h"
#import "ObsEditV2ViewController.h"

@interface ObsDetailV2ViewController () <ObsDetailViewModelDelegate, RKObjectLoaderDelegate, RKRequestDelegate>

@property IBOutlet UITableView *tableView;
@property ObsDetailViewModel *viewModel;

@end

@implementation ObsDetailV2ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.viewModel = [[ObsDetailInfoViewModel alloc] init];
    self.viewModel.observation = self.observation;
    self.viewModel.delegate = self;
    
    self.tableView.dataSource = self.viewModel;
    self.tableView.delegate = self.viewModel;
    self.tableView.estimatedRowHeight = 44;
    self.tableView.rowHeight = UITableViewAutomaticDimension;

    self.tableView.sectionHeaderHeight = CGFLOAT_MIN;
    self.tableView.sectionFooterHeight = CGFLOAT_MIN;
    
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.tableView registerClass:[DisclosureCell class] forCellReuseIdentifier:@"disclosure"];
    [self.tableView registerClass:[SubtitleDisclosureCell class] forCellReuseIdentifier:@"subtitleDisclosure"];
    
    NSDictionary *views = @{
                            @"tv": self.tableView,
                            };
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[tv]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[tv]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                                           target:self
                                                                                           action:@selector(editObs)];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self reloadObservation];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}

- (void)dealloc {
    [[[RKObjectManager sharedManager] requestQueue] cancelRequestsWithDelegate:self];
}

- (void)inat_performSegueWithIdentifier:(NSString *)identifier {
    [self performSegueWithIdentifier:identifier sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"addComment"]) {
        AddCommentViewController *vc = [segue destinationViewController];
        vc.observation = self.observation;
    } else if ([segue.identifier isEqualToString:@"addIdentification"]) {
        AddIdentificationViewController *vc = [segue destinationViewController];
        vc.observation = self.observation;
    } else if ([segue.identifier isEqualToString:@"projects"]) {
        ProjectObservationsViewController *vc = [segue destinationViewController];
        vc.isReadOnly = YES;
        vc.observation = self.observation;
    }
}

- (void)editObs {
    ObsEditV2ViewController *edit = [[ObsEditV2ViewController alloc] initWithNibName:nil bundle:nil];
    edit.shouldContinueUpdatingLocation = NO;
    edit.observation = self.observation;
    edit.isMakingNewObservation = NO;
    
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:edit];
    [self.navigationController presentViewController:nav animated:YES completion:nil];
}

- (void)reloadObservation {
    if (self.observation.needsUpload) {
        // don't clobber any local edits to this observation
        return;
    }
    // load the full observation from the server, to fetch comments, ids & faves
    [[Analytics sharedClient] debugLog:@"Network - Load complete observation details"];
    [[RKObjectManager sharedManager] loadObjectsAtResourcePath:[NSString stringWithFormat:@"/observations/%@", self.observation.recordID]
                                                 objectMapping:[Observation mapping]
                                                      delegate:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - obs detail view model delegate

- (void)selectedSection:(ObsDetailSection)section {
    switch (section) {
        case ObsDetailSectionActivity:
            self.viewModel = [[ObsDetailActivityViewModel alloc] init];
            self.viewModel.observation = self.observation;
            self.viewModel.delegate = self;

            self.tableView.dataSource = self.viewModel;
            self.tableView.delegate = self.viewModel;

            break;
        case ObsDetailSectionFaves:
            self.viewModel = [[ObsDetailFavesViewModel alloc] init];
            self.viewModel.observation = self.observation;
            self.viewModel.delegate = self;
            
            self.tableView.dataSource = self.viewModel;
            self.tableView.delegate = self.viewModel;

            break;
        case ObsDetailSectionInfo:
            self.viewModel = [[ObsDetailInfoViewModel alloc] init];
            self.viewModel.observation = self.observation;
            self.viewModel.delegate = self;
            
            self.tableView.dataSource = self.viewModel;
            self.tableView.delegate = self.viewModel;
            
            break;
        default:
            break;
    }
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [self.tableView reloadData];
    [CATransaction commit];
}

- (ObsDetailSection)activeSection {
    if ([self.viewModel isKindOfClass:[ObsDetailActivityViewModel class]]) {
        return ObsDetailSectionActivity;
    } else if ([self.viewModel isKindOfClass:[ObsDetailInfoViewModel class]]) {
        return ObsDetailSectionInfo;
    } else if ([self.viewModel isKindOfClass:[ObsDetailFavesViewModel class]]) {
        return ObsDetailSectionFaves;
    } else {
        return ObsDetailSectionNone;
    }
}

- (void)reloadRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView reloadRowsAtIndexPaths:@[ indexPath ]
                          withRowAnimation:UITableViewRowAnimationFade];
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects {
    if (objects.count == 0) return;
    
    NSError *error = nil;
    [[[RKObjectManager sharedManager] objectStore] save:&error];
    
    [self.tableView reloadData];
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
    // do what here?

}



@end
