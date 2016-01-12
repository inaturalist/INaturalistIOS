//
//  ObsDetailV2ViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/17/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import <BlocksKit/BlocksKit.h>
#import <MHVideoPhotoGallery/MHGalleryController.h>
#import <Toast/UIView+Toast.h>

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
#import "ObsDetailSelectorHeaderView.h"
#import "ObsDetailAddActivityFooter.h"
#import "ObservationPhoto.h"
#import "LocationViewController.h"
#import "ObsDetailNoInteractionHeaderFooter.h"
#import "ObsDetailAddFaveHeader.h"
#import "ObsDetailQualityDetailsFooter.h"

@interface ObsDetailV2ViewController () <ObsDetailViewModelDelegate, RKObjectLoaderDelegate, RKRequestDelegate>

@property IBOutlet UITableView *tableView;
@property ObsDetailViewModel *viewModel;
@property BOOL shouldScrollToNewestActivity;
@property UIPopoverController *sharePopover;

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
    [self.tableView registerClass:[ObsDetailSelectorHeaderView class] forHeaderFooterViewReuseIdentifier:@"selectorHeader"];
    [self.tableView registerClass:[ObsDetailAddActivityFooter class] forHeaderFooterViewReuseIdentifier:@"addActivityFooter"];
    [self.tableView registerClass:[ObsDetailNoInteractionHeaderFooter class] forHeaderFooterViewReuseIdentifier:@"noInteraction"];
    [self.tableView registerClass:[ObsDetailAddFaveHeader class] forHeaderFooterViewReuseIdentifier:@"addFave"];
    [self.tableView registerClass:[ObsDetailQualityDetailsFooter class] forHeaderFooterViewReuseIdentifier:@"qualityDetails"];

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleNSManagedObjectContextDidSaveNotification:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:[Observation managedObjectContext]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.observation.hasUnviewedActivity.boolValue) {
        [self selectedSection:ObsDetailSectionActivity];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (!self.observation.needsUpload) {
        [self reloadObservation];
    }
    
    [[Analytics sharedClient] timedEvent:kAnalyticsEventNavigateObservationDetail];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[Analytics sharedClient] endTimedEvent:kAnalyticsEventNavigateObservationDetail];
}

- (void)dealloc {
    [[[RKObjectManager sharedManager] requestQueue] cancelRequestsWithDelegate:self];
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
    } else if ([segue.identifier isEqualToString:@"taxon"]) {
        TaxonDetailViewController *vc = [segue destinationViewController];
        vc.taxon = (Taxon *)sender;
    } else if ([segue.identifier isEqualToString:@"map"]) {
        LocationViewController *location = [segue destinationViewController];
        location.observation = self.observation;
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

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if (self.shouldScrollToNewestActivity) {
        // because we're scrolling to the very last row, and tableview content sizes aren't calculated until after all the
        // subviews have laid out/etc, we need to continue scrolling to the very last row here
        NSInteger lastSection = [self.tableView numberOfSections] - 1;
        NSInteger numberOfRows = [self.tableView numberOfRowsInSection:lastSection];
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:numberOfRows - 1 inSection:lastSection]
                              atScrollPosition:UITableViewScrollPositionTop
                                      animated:YES];
        // clear the flag so we don't pin the user to the bottom of the view
        self.shouldScrollToNewestActivity = NO;
    }
}

#pragma mark - notifications

- (void)handleNSManagedObjectContextDidSaveNotification:(NSNotification *)notification {
    [self.tableView reloadData];
}

#pragma mark - obs detail view model delegate

- (void)inat_performSegueWithIdentifier:(NSString *)identifier sender:(NSObject *)object {
    if ([identifier isEqualToString:@"photos"]) {
        [[Analytics sharedClient] event:kAnalyticsEventObservationViewHiresPhoto];
        
        NSNumber *photoIndex = (NSNumber *)object;
        // can't do this in storyboards
        
        NSArray *galleryData = [self.observation.sortedObservationPhotos bk_map:^id(ObservationPhoto *op) {
            return [MHGalleryItem itemWithURL:op.largePhotoUrl.absoluteString
                                  galleryType:MHGalleryTypeImage];
        }];
        
        MHUICustomization *customization = [[MHUICustomization alloc] init];
        customization.showOverView = NO;
        customization.hideShare = YES;
        customization.useCustomBackButtonImageOnImageViewer = NO;
        
        MHGalleryController *gallery = [MHGalleryController galleryWithPresentationStyle:MHGalleryViewModeImageViewerNavigationBarShown];
        gallery.galleryItems = galleryData;
        gallery.presentationIndex = photoIndex.integerValue;
        gallery.UICustomization = customization;
        
        __weak MHGalleryController *blockGallery = gallery;
        
        gallery.finishedCallback = ^(NSUInteger currentIndex,UIImage *image,MHTransitionDismissMHGallery *interactiveTransition,MHGalleryViewMode viewMode){
            __strong typeof(blockGallery)strongGallery = blockGallery;
            dispatch_async(dispatch_get_main_queue(), ^{
                [strongGallery dismissViewControllerAnimated:YES completion:nil];
            });
        };
        
        [self presentMHGalleryController:gallery animated:YES completion:nil];
    } else if ([identifier isEqualToString:@"share"]) {
        // this isn't a storyboard thing either
        
        [[Analytics sharedClient] event:kAnalyticsEventObservationShareStarted];
        
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/observations/%ld",
                                           INatWebBaseURL, (long)self.observation.recordID.longLongValue]];
        UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[url]
                                                                               applicationActivities:nil];
        activity.completionHandler = ^(NSString *activityType, BOOL completed) {
            if (completed) {
                [[Analytics sharedClient] event:kAnalyticsEventObservationShareFinished
                                 withProperties:@{ @"destination": activityType }];
            } else {
                [[Analytics sharedClient] event:kAnalyticsEventObservationShareCancelled];

            }
        };
        
        [self presentViewController:activity animated:YES completion:nil];
    } else {
        [self performSegueWithIdentifier:identifier sender:object];
    }
}

- (void)selectedSection:(ObsDetailSection)section {
    NSString *newSectionName;
    switch (section) {
        case ObsDetailSectionActivity:
            self.viewModel = [[ObsDetailActivityViewModel alloc] init];
            self.viewModel.observation = self.observation;
            self.viewModel.delegate = self;

            self.tableView.dataSource = self.viewModel;
            self.tableView.delegate = self.viewModel;
            
            newSectionName = @"Activity";
            
            break;
        case ObsDetailSectionFaves:
            self.viewModel = [[ObsDetailFavesViewModel alloc] init];
            self.viewModel.observation = self.observation;
            self.viewModel.delegate = self;
            
            self.tableView.dataSource = self.viewModel;
            self.tableView.delegate = self.viewModel;
            
            newSectionName = @"Faves";

            break;
        case ObsDetailSectionInfo:
            self.viewModel = [[ObsDetailInfoViewModel alloc] init];
            self.viewModel.observation = self.observation;
            self.viewModel.delegate = self;
            
            self.tableView.dataSource = self.viewModel;
            self.tableView.delegate = self.viewModel;
            
            newSectionName = @"Info";

            break;
        default:
            newSectionName = @"";
            break;
    }
    
    [[Analytics sharedClient] event:kAnalyticsEventObservationChangeSection
                     withProperties:@{ @"New Section": newSectionName }];
    
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

- (void)reloadRowAtIndexPath:(NSIndexPath *)indexPath withAnimation:(UITableViewRowAnimation)animation {
    [self.tableView reloadRowsAtIndexPaths:@[ indexPath ]
                          withRowAnimation:animation];
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects {
    if (objects.count == 0) return;
    
    NSError *error = nil;
    // save will trigger a tableview reload
    [[[RKObjectManager sharedManager] objectStore] save:&error];
    
    if (self.observation.hasUnviewedActivity.boolValue && self.activeSection == ObsDetailSectionActivity) {
        
        NSInteger lastSection = [self.tableView numberOfSections] - 1;
        
        BOOL allActivityIsVisible = [[self.tableView indexPathsForVisibleRows] bk_any:^BOOL(NSIndexPath *ip) {
            return ip.section == lastSection;
        }];
        
        if (!allActivityIsVisible) {
            // show the new activity offscreen toast
            
            __weak typeof(self) weakSelf = self;
            [self.view makeToast:NSLocalizedString(@"Scroll down for newest activity", nil)
                        duration:5.0f
                        position:CSToastPositionBottom
                           title:nil
                           image:nil
                           style:nil
                      completion:^(BOOL didTap) {
                          if (didTap) {
                              __strong typeof(weakSelf) strongSelf = weakSelf;
                              
                              // set a flag so that we continue scrolling to the newest activity as the subviews get laid out
                              strongSelf.shouldScrollToNewestActivity = YES;
                              
                              // start scrolling to very last row
                              [strongSelf.tableView setContentOffset:(CGPoint){0, self.tableView.contentSize.height - self.tableView.bounds.size.height}
                                                            animated:YES];
                          }
                      }];
        } else {
            ObsDetailActivityViewModel *activityViewModel = (ObsDetailActivityViewModel *)self.viewModel;
            [activityViewModel markActivityAsSeen];
        }
    }
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
    // do what here?

}



@end
