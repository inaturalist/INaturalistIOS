//
//  ObsDetailV2ViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/17/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

@import AVKit;

#import <BlocksKit/BlocksKit.h>
#import <MHVideoPhotoGallery/MHGalleryController.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <ARSafariActivity/ARSafariActivity.h>
#import <Realm/Realm.h>

#import "ObsDetailV2ViewController.h"
#import "ObsDetailViewModel.h"
#import "DisclosureCell.h"
#import "SubtitleDisclosureCell.h"
#import "ObsDetailActivityViewModel.h"
#import "ObsDetailInfoViewModel.h"
#import "ObsDetailFavesViewModel.h"
#import "AddCommentViewController.h"
#import "AddIdentificationViewController.h"
#import "ObsEditV2ViewController.h"
#import "ObsDetailSelectorHeaderView.h"
#import "ObsDetailAddActivityFooter.h"
#import "ObservationPhoto.h"
#import "LocationViewController.h"
#import "ObsDetailNoInteractionHeaderFooter.h"
#import "ObsDetailAddFaveHeader.h"
#import "ObsDetailQualityDetailsFooter.h"
#import "ObservationValidationErrorView.h"
#import "INatPhoto.h"
#import "ExploreObservation.h"
#import "ObservationAPI.h"
#import "ExploreObservationRealm.h"
#import "ImageStore.h"
#import "INatSound.h"
#import "iNaturalist-Swift.h"

@interface ObsDetailV2ViewController () <ObsDetailViewModelDelegate>

@property IBOutlet UITableView *tableView;
@property ObsDetailViewModel *viewModel;
@property BOOL shouldScrollToNewestActivity;
@property UIPopoverController *sharePopover;
@property MBProgressHUD *progressHud;
@property RLMNotificationToken *obsChangedToken;

@end

@implementation ObsDetailV2ViewController

- (ObservationAPI *)observationApi {
    static ObservationAPI *_api = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _api = [[ObservationAPI alloc] init];
    });
    return _api;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if ([self.observation hasUnviewedActivityBool] || self.shouldShowActivityOnLoad) {
        self.viewModel = [[ObsDetailActivityViewModel alloc] init];
        self.viewModel.observation = self.observation;
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            CGPoint offset = CGPointMake(0, self.tableView.contentSize.height - self.tableView.frame.size.height);
            [self.tableView setContentOffset:offset animated:YES];
        });
    } else {
        self.viewModel = [[ObsDetailInfoViewModel alloc] init];
    }
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
    
    // we share this cell design with the obs edit screen (and eventually others)
    // so we load it from a nib rather than from the storyboard, which locks the
    // cell into a single view controller scene
    [self.tableView registerNib:[UINib nibWithNibName:@"TaxonCell" bundle:nil] forCellReuseIdentifier:@"taxonFromNib"];


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
    
    if ([self.observation isEditable]) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                                               target:self
                                                                                               action:@selector(editObs)];
    }
    
    if ([self.observation isKindOfClass:[ExploreObservationRealm class]]) {
        // we want to observe changes on it, reload the UI if the object changes
        ExploreObservationRealm *eor = [ExploreObservationRealm objectForPrimaryKey:self.observation.uuid];
        __weak typeof(self)weakSelf = self;
        self.obsChangedToken = [eor addNotificationBlock:^(BOOL deleted, NSArray<RLMPropertyChange *> * _Nullable changes, NSError * _Nullable error) {
            if (!deleted) {
                [weakSelf.tableView reloadData];
            }
        }];
    }
}

- (void)dealloc {
    [self.obsChangedToken invalidate];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // reload the tableview in case we've just come from editing view
    [self.tableView reloadData];

    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
    [UIView animateWithDuration:0.3 animations:^{
        [self.navigationController.navigationBar setBackgroundImage:nil
                                                      forBarMetrics:UIBarMetricsDefault];
        self.navigationController.navigationBar.shadowImage = nil;
        self.navigationController.navigationBar.translucent = NO;
    }];
    
    [self configureValidationErrorView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // don't clobber any un-uploaded edits to this observation or its children
    if (!self.observation.needsUpload || self.observation.childrenNeedingUpload.count != 0) {
        [self reloadObservation];
    }
}

- (void)uploadFinished {
    [self configureValidationErrorView];
}

- (void)configureValidationErrorView {
    if (self.observation.validationErrorMsg && self.observation.validationErrorMsg.length > 0) {
        self.tableView.tableHeaderView = ({
            ObservationValidationErrorView *view = [[ObservationValidationErrorView alloc] initWithFrame:CGRectMake(0, 0, self.tableView.bounds.size.width, 100)];
            view.validationError = self.observation.validationErrorMsg;
            view;
        });
    } else {
        self.tableView.tableHeaderView = nil;
    }

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"addComment"]) {
        AddCommentViewController *vc = [segue destinationViewController];
        vc.observation = self.observation;
        vc.onlineEditingDelegate = self;
    } else if ([segue.identifier isEqualToString:@"addIdentification"]) {
        AddIdentificationViewController *vc = [segue destinationViewController];
        vc.observation = self.observation;
        vc.onlineEditingDelegate = self;
    } else if ([segue.identifier isEqualToString:@"taxon"]) {
        NSInteger taxonId = [sender integerValue];

        TaxonDetailViewController *vc = [segue destinationViewController];
        vc.taxonId = taxonId;
        vc.observationCoordinate = [self.observation visibleLocation];
    } else if ([segue.identifier isEqualToString:@"map"]) {
        LocationViewController *location = [segue destinationViewController];
        location.observation = self.observation;
    }
}

- (void)editObs {
    if ([self.observation isEditable] && [self.observation isKindOfClass:ExploreObservationRealm.class]) {
        ObsEditV2ViewController *edit = [[ObsEditV2ViewController alloc] initWithNibName:nil bundle:nil];
        edit.shouldContinueUpdatingLocation = NO;
        edit.persistedObservation = (ExploreObservationRealm *)self.observation;
        edit.isMakingNewObservation = NO;
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:edit];
        [self.navigationController presentViewController:nav animated:YES completion:nil];
    }
}

- (void)reloadObservation {
    if (self.observation.needsUpload || self.observation.childrenNeedingUpload.count != 0) {
        // don't clobber any un-uploaded edits to this observation or its children
        return;
    }
    
    NSInteger obsIdToReload = 0;
    if (self.observation) {
        obsIdToReload = self.observation.recordId;
    } else {
        obsIdToReload = self.observationId;
    }
    
    if (obsIdToReload == 0) {
        // nothing to reload
        return;
    }
    
    // load the full observation from the server, to fetch comments, ids & faves
    __weak typeof(self)weakSelf = self;
    [[self observationApi] observationWithId:obsIdToReload handler:^(NSArray *results, NSInteger count, NSError *error) {
        if (results.count != 1) { return; }
        if (!weakSelf) { return; }
        
        if ([weakSelf.observation isKindOfClass:ExploreObservation.class]) {
            weakSelf.observation = results.firstObject;
            weakSelf.viewModel.observation = results.firstObject;
        } else {
            // we need to serialize the observation
            RLMRealm *realm = [RLMRealm defaultRealm];
            id obsValue = [ExploreObservationRealm valueForMantleModel:results.firstObject];
            [realm beginWriteTransaction];
            ExploreObservationRealm *o = [ExploreObservationRealm createOrUpdateInRealm:realm
                                                                              withValue:obsValue];
            [o setSyncedForSelfAndChildrenAt:[NSDate date]];
            [realm commitWriteTransaction];
        }
        
        [weakSelf.tableView reloadData];
    }];
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

#pragma mark - ObservationOnlineEditingDelegate

- (void)editorCancelled {
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)editorEditedObservationOnline {
    [self reloadObservation];
    if (self.presentedViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - obs detail view model delegate

- (void)noticeWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showProgressHud {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressHud = [MBProgressHUD showHUDAddedTo:self.tableView animated:YES];
        self.progressHud.removeFromSuperViewOnHide = YES;
        self.progressHud.dimBackground = YES;
    });
}

- (void)hideProgressHud {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressHud hide:YES];
    });
}

- (void)inat_performSegueWithIdentifier:(NSString *)identifier sender:(NSObject *)object {
    if ([identifier isEqualToString:@"photos"]) {
        NSNumber *photoIndex = (NSNumber *)object;
        // can't do this in storyboards
        
        NSArray *galleryData = [self.observation.sortedObservationPhotos bk_map:^id(id <INatPhoto> op) {
            UIImage *img = [[ImageStore sharedImageStore] find:op.photoKey forSize:ImageStoreSmallSize];
            if (img) {
                return [MHGalleryItem itemWithImage:img];
            } else {
                return [MHGalleryItem itemWithURL:op.largePhotoUrl.absoluteString
                                      galleryType:MHGalleryTypeImage];
            }
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
        
        gallery.finishedCallback = ^(NSInteger currentIndex, UIImage *image, MHTransitionDismissMHGallery *interactiveTransition, MHGalleryViewMode viewMode) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [blockGallery dismissViewControllerAnimated:YES completion:nil];
            });
        };
        
        [self presentMHGalleryController:gallery animated:YES completion:nil];
    } else if ([identifier isEqualToString:@"sound"]) {
        
        NSNumber *mediaIndex = (NSNumber *)object;
        id media = [self.observation.observationMedia objectAtIndex:[mediaIndex integerValue]];
        if ([media conformsToProtocol:@protocol(INatSound)]) {
            
            NSURL *soundUrl = nil;
            
            id <INatSound> sound = (id <INatSound>)media;
            MediaStore *ms = [[MediaStore alloc] init];
            NSFileManager *fm = [NSFileManager defaultManager];
            NSURL *localMediaUrl = [ms mediaUrlForKey:sound.mediaKey];
            if (localMediaUrl && [fm fileExistsAtPath:localMediaUrl.path]) {
                soundUrl = localMediaUrl;
            } else {
                soundUrl = [sound mediaUrl];
            }
            
            // request speaker audio output
            NSError *error = nil;
            AVAudioSession *session = [AVAudioSession sharedInstance];
            BOOL categorySuccess = [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
            BOOL overrideSuccess = [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker
                                                              error:&error];
            if (categorySuccess && overrideSuccess && !error) {
                [session setActive:YES error:&error];
            }
                        
            AVPlayer *player = [[AVPlayer alloc] initWithURL:soundUrl];
            AVPlayerViewController *playerVC = [[AVPlayerViewController alloc] initWithNibName:nil bundle:nil];
            playerVC.player = player;
            
            [self presentViewController:playerVC animated:YES completion:^{
                [player play];
            }];

        }
        
    } else if ([identifier isEqualToString:@"share"]) {
        // this isn't a storyboard thing either
        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/observations/%ld",
                                           INatWebBaseURL, (long)self.observation.inatRecordId]];
        
        ARSafariActivity *safariActivity = [[ARSafariActivity alloc] init];
        
        UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[url]
                                                                               applicationActivities:@[safariActivity]];
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            UIButton *shareButton = (UIButton *)object;
            CGRect frame = [self.view convertRect:shareButton.frame
                                         fromView:shareButton.superview];
            UIPopoverController *popover = [[UIPopoverController alloc] initWithContentViewController:activity];
            [popover presentPopoverFromRect:frame
                                     inView:self.view
                   permittedArrowDirections:UIPopoverArrowDirectionAny
                                   animated:YES];
        } else {
            [self presentViewController:activity animated:YES completion:nil];
        }
    } else {
        [self performSegueWithIdentifier:identifier sender:object];
    }
}

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
    
    [self.tableView reloadData];
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

- (void)reloadTableView {
    [self.tableView reloadData];
}

- (void)reloadRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[ indexPath ]
                          withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
}

- (void)reloadRowAtIndexPath:(NSIndexPath *)indexPath withAnimation:(UITableViewRowAnimation)animation {
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[ indexPath ]
                          withRowAnimation:animation];
    [self.tableView endUpdates];
}

@end
