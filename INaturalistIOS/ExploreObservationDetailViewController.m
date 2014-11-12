//
//  ExploreObservationDetailViewController.m
//  Explore Prototype
//
//  Created by Alex Shepard on 10/10/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>
#import <FontAwesomeKit/FAKIonIcons.h>
#import <CoreLocation/CoreLocation.h>
#import <RestKit/RestKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <MHVideoPhotoGallery/MHGalleryController.h>
#import <MHVideoPhotoGallery/MHGallery.h>
#import <MHVideoPhotoGallery/MHTransitionDismissMHGallery.h>

#import "ExploreObservationDetailViewController.h"
#import "ExploreObservation.h"
#import "ExploreObservationPhoto.h"
#import "ExploreMappingProvider.h"
#import "ExploreIdentification.h"
#import "ExploreComment.h"
#import "ExploreIdentificationCell.h"
#import "ExploreCommentCell.h"
#import "ExploreObservationDetailHeader.h"
#import "UIColor+ExploreColors.h"
#import "Analytics.h"
#import "TaxonDetailViewController.h"
#import "Taxon.h"
#import "TaxaSearchViewController.h"
#import "ExploreObservationsDataSource.h"
#import "ExploreObservationsController.h"

@interface ExploreObservationDetailViewController () <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, TaxaSearchViewControllerDelegate> {
    ExploreObservation *_observation;
    
    NSArray *commentsAndIds;
    
    UIActionSheet *shareActionSheet;
    UIActionSheet *identifyActionSheet;
    
    ExploreIdentification *selectedIdentification;
}

@end

@implementation ExploreObservationDetailViewController

#pragma mark - UIView lifecycle

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithTableViewStyle:UITableViewStyleGrouped]) {
        self.title = @"Details";
        UIBarButtonItem *share = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                               target:self
                                                                               action:@selector(action)];
        FAKIcon *tagIcon = [FAKIonIcons ios7PricetagOutlineIconWithSize:30.0f];
        FAKIcon *smallTagIcon = [FAKIonIcons ios7PricetagOutlineIconWithSize:25.0f];
        [tagIcon addAttribute:NSForegroundColorAttributeName value:[UIColor inatGreen]];
        UIBarButtonItem *tag = [[UIBarButtonItem alloc] initWithImage:[tagIcon imageWithSize:CGSizeMake(30, 30)]
                                                  landscapeImagePhone:[smallTagIcon imageWithSize:CGSizeMake(25, 25)]
                                                                style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(tag)];
        self.navigationItem.rightBarButtonItems = @[tag, share];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.bounces = YES;
    self.undoShakingEnabled = NO;
    self.keyboardPanningEnabled = YES;
    self.inverted = NO;
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerClass:[ExploreIdentificationCell class] forCellReuseIdentifier:@"IdentificationCell"];
    [self.tableView registerClass:[ExploreCommentCell class] forCellReuseIdentifier:@"CommentCell"];
    
    self.textView.placeholder = @"Add a comment";
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[Analytics sharedClient] timedEvent:kAnalyticsEventNavigateExploreObsDetails];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[Analytics sharedClient] endTimedEvent:kAnalyticsEventNavigateExploreObsDetails];
}

#pragma mark - Show Taxon Details Helper

- (void)showTaxonDetailsForTaxonId:(NSInteger)taxonId {
    if (![[RKClient sharedClient] reachabilityObserver].isNetworkReachable) {
        [SVProgressHUD showErrorWithStatus:@"Couldn't load Taxon Details"];
        return;
    }
    
    NSString *path = [NSString stringWithFormat:@"/taxa/%ld.json", (long)taxonId];
    [[RKObjectManager sharedManager] loadObjectsAtResourcePath:path usingBlock:^(RKObjectLoader *loader) {
        loader.method = RKRequestMethodGET;
        loader.objectMapping = [Taxon mapping];
        
        loader.onDidLoadObject = ^(id object) {
            TaxonDetailViewController *tdvc = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:NULL]
                                               instantiateViewControllerWithIdentifier:@"TaxonDetailViewController"];
            tdvc.taxon = object;
            [self.navigationController pushViewController:tdvc animated:YES];
        };
        
        loader.onDidFailLoadWithError = ^(NSError *err) {
            [SVProgressHUD showErrorWithStatus:@"Couldn't load Taxon Details"];
        };
        
        loader.onDidFailWithError = ^(NSError *err) {
            [SVProgressHUD showErrorWithStatus:@"Couldn't load Taxon Details"];
        };
    }];
    
}

#pragma mark - UIBarButton targets

- (void)action {
    shareActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                     destructiveButtonTitle:nil
                                          otherButtonTitles:@"Open in Safari", @"Share", nil];
    [shareActionSheet showInView:self.view];
}

- (void)tag {
    if (![[NSUserDefaults standardUserDefaults] valueForKey:INatTokenPrefKey]) {
        [[[UIAlertView alloc] initWithTitle:@"You must be logged in"
                                    message:@"No anonymous identifications!"
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
        return;
    }
    
    TaxaSearchViewController *tsvc = [[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:NULL]
                                      instantiateViewControllerWithIdentifier:@"TaxaSearchViewController"];
    [tsvc setDelegate:self];
    tsvc.hidesDoneButton = YES;
    [self.navigationController pushViewController:tsvc animated:YES];
}

#pragma mark - UIActionSheetDelegate

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (actionSheet == shareActionSheet) {
        switch (buttonIndex) {
            case 0:
                // open in safari
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://inaturalist.org/observations/%ld",
                                                                                 (long)self.observation.observationId]]];
                break;
            case 1:
                // share
                [self shareObservation:self.observation];
                break;
            default:
                break;
        }
    } else if (actionSheet == identifyActionSheet) {
        switch (buttonIndex) {
            case 0:
                // view taxa details
                [self showTaxonDetailsForTaxonId:selectedIdentification.identificationTaxonId];
                break;
            case 1:
                // agree
                if ([[NSUserDefaults standardUserDefaults] valueForKey:INatTokenPrefKey]) {
                    [[Analytics sharedClient] event:kAnalyticsEventExploreAddIdentification
                                     withProperties:@{ @"Via": @"Agree" }];
                    [self addIdentificationWithTaxonId:selectedIdentification.identificationTaxonId];
                } else {
                    [[[UIAlertView alloc] initWithTitle:@"You must be logged in"
                                                message:@"No anonymous identifications!"
                                               delegate:nil
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil] show];
                }
                break;
            default:
                break;
        }
        selectedIdentification = nil;
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    selectedIdentification = nil;
}

- (void)actionSheetCancel:(UIActionSheet *)actionSheet {
    selectedIdentification = nil;
}

#pragma mark - ActionSheet targets

- (void)shareObservation:(ExploreObservation *)observation {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://inaturalist.org/observations/%ld", (long)self.observation.observationId]];
    UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[url]
                                                                           applicationActivities:nil];
    activity.completionHandler = ^(NSString *activityType, BOOL completed) {
        if (completed)
            [[Analytics sharedClient] event:kAnalyticsEventExploreObservationShare
                             withProperties:@{ @"destination": activityType }];
    };
    [self presentViewController:activity animated:YES completion:nil];
}

#pragma mark - Setter/getter for observation

- (void)setObservation:(ExploreObservation *)observation {
    _observation = observation;
    
    if (![observation commentsAndIdentificationsSynchronized])
        [self fetchObservationCommentsAndIds];
    
    [self.view setNeedsLayout];
}

- (ExploreObservation *)observation {
    return _observation;
}

# pragma mark - UITableView datasource/delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    selectedIdentification = nil;
    id object = [commentsAndIds objectAtIndex:indexPath.item];
    
    if ([object isKindOfClass:[ExploreIdentification class]]) {
        selectedIdentification = object;
        // present action sheet allowing user to agree or view taxon details
        identifyActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                          delegate:self
                                                 cancelButtonTitle:@"Cancel"
                                            destructiveButtonTitle:nil
                                                 otherButtonTitles:@"View Taxon Details", @"Agree", nil];
        [identifyActionSheet showInView:self.view];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return [ExploreObservationDetailHeader heightForObservation:self.observation];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    ExploreObservationDetailHeader *view = [[ExploreObservationDetailHeader alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 200)];
    [view setObservation:self.observation];
    
    if (self.observation.observationPhotos.count > 0) {
        
        view.photoImageView.userInteractionEnabled = YES;
        [view.photoImageView addGestureRecognizer:[UITapGestureRecognizer bk_recognizerWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
            
            NSArray *galleryData = [self.observation.observationPhotos bk_map:^id(ExploreObservationPhoto *observationPhoto) {
                return [MHGalleryItem itemWithURL:observationPhoto.largeURL thumbnailURL:observationPhoto.thumbURL];
            }];
            
            MHUICustomization *customization = [[MHUICustomization alloc] init];
            customization.showOverView = NO;
            customization.showMHShareViewInsteadOfActivityViewController = NO;
            customization.hideShare = YES;
            customization.useCustomBackButtonImageOnImageViewer = NO;
            
            MHGalleryController *gallery = [MHGalleryController galleryWithPresentationStyle:MHGalleryViewModeImageViewerNavigationBarHidden];
            gallery.galleryItems = galleryData;
            gallery.presentingFromImageView = view.photoImageView;
            gallery.presentationIndex = 0;
            gallery.UICustomization = customization;
            
            __weak MHGalleryController *blockGallery = gallery;
            
            gallery.finishedCallback = ^(NSUInteger currentIndex,UIImage *image,MHTransitionDismissMHGallery *interactiveTransition,MHGalleryViewMode viewMode){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [blockGallery dismissViewControllerAnimated:YES dismissImageView:view.photoImageView completion:nil];
                });
            };
            [self presentMHGalleryController:gallery animated:YES completion:nil];
        }]];
    }
    
    [@[view.commonNameLabel, view.scientificNameLabel] bk_each:^(UILabel *label) {
        label.userInteractionEnabled = YES;
        [label addGestureRecognizer:[UITapGestureRecognizer bk_recognizerWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
            if (self.observation.taxonId != 0) {
                [self showTaxonDetailsForTaxonId:self.observation.taxonId];
            }
        }]];
    }];
    
    return view;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return commentsAndIds.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    id object = [commentsAndIds objectAtIndex:indexPath.item];
    if ([object isKindOfClass:[ExploreIdentification class]]) {
        ExploreIdentificationCell *cell = [tableView dequeueReusableCellWithIdentifier:@"IdentificationCell"];
        cell.identification = object;
        return cell;
    } else if ([object isKindOfClass:[ExploreComment class]]) {
        ExploreCommentCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CommentCell"];
        cell.comment = object;
        return cell;
    }
    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    id item = [commentsAndIds objectAtIndex:indexPath.item];
    
    if ([item isKindOfClass:[ExploreIdentification class]]) {
        return [ExploreIdentificationCell rowHeightForIdentification:(ExploreIdentification *)item
                                                           withWidth:tableView.frame.size.width];
        
    } else if ([item isKindOfClass:[ExploreComment class]]) {
        return [ExploreCommentCell rowHeightForComment:(ExploreComment *)item
                                             withWidth:tableView.frame.size.width];
    } else {
        return 0.0f;
    }
}


#pragma mark - TaxaSearchViewControllerDelegate

- (void)taxaSearchViewControllerChoseTaxon:(Taxon *)taxon {
    [[Analytics sharedClient] event:kAnalyticsEventExploreAddIdentification
                     withProperties:@{ @"Via": @"Taxon Chooser" }];
    [self addIdentificationWithTaxonId:taxon.recordID.integerValue];
}

#pragma mark - SLKTableView methods

- (void)didPressRightButton:(id)sender {
    // Notifies the view controller when the right button's action has been triggered, manually or by using the keyboard return key.
    
    // This little trick validates any pending auto-correction or auto-spelling just after hitting the 'Send' button
    [self.textView refreshFirstResponder];
    [self.textView resignFirstResponder];

    if ([[NSUserDefaults standardUserDefaults] valueForKey:INatTokenPrefKey]) {
        [self addComment:self.textView.text];
    } else {
        [[[UIAlertView alloc] initWithTitle:@"You must be logged in"
                                    message:@"No anonymous comments!"
                                   delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil] show];
    }
    
    [super didPressRightButton:sender];
}

#pragma mark - iNat API Calls

- (void)addIdentificationWithTaxonId:(NSInteger)taxonId {
    [SVProgressHUD showWithStatus:@"Adding Identification..." maskType:SVProgressHUDMaskTypeGradient];
    
    ExploreObservationsController *controller = [[ExploreObservationsController alloc] init];
    [controller addIdentificationTaxonId:taxonId forObservation:self.observation completionHandler:^(RKResponse *response, NSError *error) {
        if (error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showErrorWithStatus:@"Identification failed :("];
            });
        } else {
            // if it wasn't an "agree" id, then we need to pop back through the taxon chooser to this VC
            [self.navigationController popToRootViewControllerAnimated:YES];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [SVProgressHUD showSuccessWithStatus:@"Added!"];
            });
            [self fetchObservationCommentsAndIds];
        }
    }];
}

- (void)addComment:(NSString *)commentBody {
    [SVProgressHUD showWithStatus:@"Adding Comment..." maskType:SVProgressHUDMaskTypeGradient];
    
    ExploreObservationsController *controller = [[ExploreObservationsController alloc] init];
    [controller addComment:commentBody
            forObservation:self.observation
         completionHandler:^(RKResponse *response, NSError *error) {
             if (error) {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [SVProgressHUD showErrorWithStatus:@"Comment failed :("];
                 });
             } else {
                 [[Analytics sharedClient] event:kAnalyticsEventExploreAddComment];
                 // update the UI
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [SVProgressHUD showSuccessWithStatus:@"Added!"];
                 });
                 [self fetchObservationCommentsAndIds];
             }
    }];
}

- (void)fetchObservationCommentsAndIds {
    ExploreObservationsController *controller = [[ExploreObservationsController alloc] init];
    [controller loadCommentsAndIdentificationsForObservation:self.observation
                                           completionHandler:^(NSArray *results, NSError *error) {
                                               if (error) {
                                                   [SVProgressHUD showErrorWithStatus:error.localizedDescription];
                                               } else {
                                                   ExploreObservation *observation = (ExploreObservation *)results.firstObject;
                                                   
                                                   // interleave comments and ids together, sorted by date
                                                   NSMutableArray *array = [NSMutableArray array];
                                                   [array addObjectsFromArray:observation.comments];
                                                   [array addObjectsFromArray:observation.identifications];
                                                   [array sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                                                       return [[obj1 performSelector:@selector(date)] compare:[obj2 performSelector:@selector(date)]];
                                                   }];
                                                   commentsAndIds = [NSArray arrayWithArray:array];
                                                   
                                                   dispatch_async(dispatch_get_main_queue(), ^{
                                                       [self.tableView reloadData];
                                                   });
                                               }
                                           }];
    
}

@end
