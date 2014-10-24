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
#import <AFOAuth2Client/AFOAuth2Client.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <MHVideoPhotoGallery/MHGalleryController.h>
#import <MHVideoPhotoGallery/MHGallery.h>
#import <MHVideoPhotoGallery/MHTransitionDismissMHGallery.h>
#import <FlurrySDK/Flurry.h>

#import "ExploreObservationDetailViewController.h"
#import "ExploreObservation.h"
#import "ExploreObservationPhoto.h"
#import "ExploreMappingProvider.h"
#import "ExploreIdentification.h"
#import "ExploreComment.h"
#import "ExploreIdentificationCell.h"
#import "ExploreCommentCell.h"
#import "ExploreObservationDetailHeader.h"
#import "ExploreTaxonDetailsViewController.h"
#import "UIColor+ExploreColors.h"

static NSDateFormatter *shortDateFormatter;
static NSDateFormatter *shortTimeFormatter;

@interface ExploreObservationDetailViewController () <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate> {
    ExploreObservation *_observation;
        
    UILabel *commonNameLabel;
    UILabel *scientificNameLabel;
    UIImageView *photoImageView;
    
    UIImageView *observerAvatarImageView;
    UILabel *observerNameLabel;
    UILabel *observedDateLabel;
    UILabel *observedTimeLabel;
    
    UILabel *mapPinLabel;
    UILabel *observedLocationLabel;
    
    UIView *separatorView;
    
    NSArray *commentsAndIds;
    
    CLGeocoder *geocoder;
    
    UIActionSheet *shareActionSheet;
    UIActionSheet *identifyActionSheet;
    
    ExploreIdentification *selectedIdentification;
}

@end

@implementation ExploreObservationDetailViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithTableViewStyle:UITableViewStyleGrouped]) {
        self.title = @"Details";
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                               target:self
                                                                                               action:@selector(action)];
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
    
    [Flurry logEvent:@"Navigate - Explore Observation Details" timed:YES];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [Flurry endTimedEvent:@"Navigate - Explore Observation Details" withParameters:nil];
}

- (void)action {
    shareActionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                     destructiveButtonTitle:nil
                                          otherButtonTitles:@"Open in Safari", @"Share", nil];
    [shareActionSheet showInView:self.view];
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
                [self showTaxaDetailsForIdentification:selectedIdentification];
                break;
            case 1:
                // agree
                [self agreeWithIdentification:selectedIdentification];
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

#pragma mark - ActionSheet items

- (void)shareObservation:(ExploreObservation *)observation {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://inaturalist.org/observations/%ld", (long)self.observation.observationId]];
    UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[url]
                                                                           applicationActivities:nil];
    [self presentViewController:activity animated:YES completion:nil];
}

- (void)showTaxaDetailsForIdentification:(ExploreIdentification *)identification {
    ExploreTaxonDetailsViewController *taxaDetails = [[ExploreTaxonDetailsViewController alloc] initWithNibName:nil bundle:nil];
    taxaDetails.taxonId = identification.identificationTaxonId;
    [self.navigationController pushViewController:taxaDetails animated:YES];
}

- (void)agreeWithIdentification:(ExploreIdentification *)identification {
    [self addIdentification:identification.identificationTaxonId];
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
    
    [@[view.commonNameLabel, view.scientificNameLabel] bk_each:^(UILabel *label) {
        label.userInteractionEnabled = YES;
        [label addGestureRecognizer:[UITapGestureRecognizer bk_recognizerWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
            if (self.observation.taxonId != 0) {
                ExploreTaxonDetailsViewController *taxaDetails = [[ExploreTaxonDetailsViewController alloc] initWithNibName:nil bundle:nil];
                taxaDetails.taxonId = self.observation.taxonId;
                [self.navigationController pushViewController:taxaDetails animated:YES];
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

#pragma mark - SLKTableView methods

- (void)didPressRightButton:(id)sender
{
    // Notifies the view controller when the right button's action has been triggered, manually or by using the keyboard return key.
    
    // This little trick validates any pending auto-correction or auto-spelling just after hitting the 'Send' button
    [self.textView refreshFirstResponder];
    [self.textView resignFirstResponder];
    
    NSString *message = [self.textView.text copy];
    [self addComment:message];
    
    [super didPressRightButton:sender];
}

#pragma mark - iNat API Calls

- (void)addIdentification:(NSInteger)taxonId {
    /*
     RESTKIT 0.20
     
    [SVProgressHUD showWithStatus:@"Adding Identification..." maskType:SVProgressHUDMaskTypeGradient];
    
    // doing this with AFNetworking because RESTKit/OAuth is hurting my brain right now
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:@"http://inaturalist.org"]];
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST"
                                                            path:@"/identifications.json"
                                                      parameters:@{@"identification[observation_id]": @(self.observation.observationId),
                                                                   @"identification[taxon_id]": @(taxonId)}];
    
    AFOAuthCredential *credential = [AFOAuthCredential retrieveCredentialWithIdentifier:@"inaturalist.org"];
    [request addValue:[NSString stringWithFormat:@"Bearer %@", credential.accessToken] forHTTPHeaderField:@"Authorization"];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                        success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                                                            // update the UI
                                                                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                                                                [SVProgressHUD showSuccessWithStatus:@"Added!"];
                                                                                            });
                                                                                            [self fetchObservationCommentsAndIds];
                                                                                        }
                                                                                        failure:^( NSURLRequest *request , NSHTTPURLResponse *response , NSError *error , id JSON ) {
                                                                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                                                                [SVProgressHUD showErrorWithStatus:@"Identification failed :("];
                                                                                            });
                                                                                        }];
    [operation start];
     */
}

- (void)addComment:(NSString *)comment {
    /*
     
     RESTKIT 0.20
    [SVProgressHUD showWithStatus:@"Adding Comment..." maskType:SVProgressHUDMaskTypeGradient];

    // doing this with AFNetworking because RESTKit/OAuth is hurting my brain right now
    AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:@"http://inaturalist.org"]];
    NSMutableURLRequest *request = [httpClient requestWithMethod:@"POST"
                                                            path:@"/comments.json"
                                                      parameters:@{@"comment[parent_type]": @"Observation",
                                                                   @"comment[parent_id]": @(self.observation.observationId),
                                                                   @"comment[body]": comment}];
    
    AFOAuthCredential *credential = [AFOAuthCredential retrieveCredentialWithIdentifier:@"inaturalist.org"];
    [request addValue:[NSString stringWithFormat:@"Bearer %@", credential.accessToken] forHTTPHeaderField:@"Authorization"];
    
    AFJSONRequestOperation *operation = [AFJSONRequestOperation JSONRequestOperationWithRequest:request
                                                                                        success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
                                                                                             // update the UI
                                                                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                                                                [SVProgressHUD showSuccessWithStatus:@"Added!"];
                                                                                            });
                                                                                            [self fetchObservationCommentsAndIds];
                                                                                        }
                                                                                        failure:^( NSURLRequest *request , NSHTTPURLResponse *response , NSError *error , id JSON ) {
                                                                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                                                                [SVProgressHUD showErrorWithStatus:@"Comment failed :("];
                                                                                            });
                                                                                        }];
    [operation start];
     */
}

- (void)fetchObservationCommentsAndIds {
    
    /*
     RESTKIT 0.20
     
    NSIndexSet *statusCodeSet = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful);
    RKMapping *mapping = [ExploreMappingProvider observationMapping];
    
    NSString *baseURL = [NSString stringWithFormat:@"http://www.inaturalist.org/observations/%ld.json",
                         (long)self.observation.observationId];
    NSString *pathPattern = [NSString stringWithFormat:@"/observations/%ld.json", (long)self.observation.observationId];
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping
                                                                                            method:RKRequestMethodGET
                                                                                       pathPattern:pathPattern
                                                                                           keyPath:@""
                                                                                       statusCodes:statusCodeSet];
    
    NSURL *url = [NSURL URLWithString:baseURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request
                                                                        responseDescriptors:@[responseDescriptor]];
    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        if (mappingResult.count == 1) {
            ExploreObservation *observation = (ExploreObservation *)mappingResult.firstObject;
            
            NSMutableArray *array = [NSMutableArray array];
            [array addObjectsFromArray:observation.comments];
            [array addObjectsFromArray:observation.identifications];
            
            [array sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                return [[obj1 performSelector:@selector(date)] compare:[obj2 performSelector:@selector(date)]];
            }];
            
            commentsAndIds = [NSArray arrayWithArray:array];
            
            //self.observation = observation;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadData];
            });
        }
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        NSLog(@"error: %@", error.localizedDescription);
    }];
    
    [operation start];
     */

}

@end
