//
//  TaxonDetailViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/23/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

@import MapKit;
@import FontAwesomeKit;
@import AFNetworking;
@import UIColor_HTMLColors;
@import ARSafariActivity;
@import JDFTooltips;

#import "TaxonDetailViewController.h"
#import "TaxaAPI.h"
#import "ExploreTaxon.h"
#import "ExploreTaxonRealm.h"
#import "Observation.h"
#import "TaxonPhoto.h"
#import "ImageStore.h"
#import "UIColor+INaturalist.h"
#import "Analytics.h"
#import "NSURL+INaturalist.h"
#import "TaxonPhotoCell.h"
#import "TaxonSummaryCell.h"
#import "RoundedButtonCell.h"
#import "TaxonPhotoPageViewController.h"
#import "TaxonMapCell.h"
#import "TaxonMapViewController.h"
#import "INatPhoto.h"
#import "TaxonSelectButtonCell.h"
#import "INatReachability.h"

@interface INatCopyNameActivity: UIActivity
@property NSString *inatName;
@end


@interface TaxonDetailViewController () <MKMapViewDelegate>
@property ExploreTaxonRealm *fullTaxon;
@property MKMapRect mapRect;
@property NSInteger numberOfObservations;

@property IBOutlet UIButton *infoButton;
@property JDFTooltipView *tooltip;
@end

@implementation TaxonDetailViewController

#pragma mark - Action Targets

- (void)shareTapped:(UIBarButtonItem *)selector {
    if (!self.fullTaxon) { return; }
    NSURL *url = [self moreDetailsURL];
    if (!url) {
        return;
    }
        
    ARSafariActivity *openInSafari = [[ARSafariActivity alloc] init];
    INatCopyNameActivity *copyName = [[INatCopyNameActivity alloc] init];
    UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[url, self.fullTaxon.scientificName]
                                                                           applicationActivities:@[openInSafari, copyName]];
        
    // does this work on iPad?
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        activity.modalPresentationStyle = UIModalPresentationPopover;
        activity.popoverPresentationController.barButtonItem = selector;
    }
    
    [self presentViewController:activity animated:YES completion:nil];
    
}

- (void)actionTapped:(id)sender {
    if (!self.fullTaxon) { return; }
    [self.delegate taxonDetailViewControllerClickedActionForTaxonId:self.taxonId];
}


- (void)infoTapped:(id)sender {
    if (!self.fullTaxon) { return; }
    
    if ([UIApplication.sharedApplication canOpenURL:[self moreDetailsURL]]) {
        [UIApplication.sharedApplication openURL:[self moreDetailsURL]
                                         options:@{}
                               completionHandler:nil];
    }
}

- (void)toggleTooltipInView:(UIView *)view parentView:(UIView *)parentView {
    if (self.tooltip) {
        // unclear why JDFTooltipView doesn't set/honor -hidden when
        // performing -hideAnimated: and -show
        if (self.tooltip.hidden) {
            self.tooltip.hidden = NO;
        } else {
            self.tooltip.hidden = YES;
        }
    } else {
        self.tooltip = [[JDFTooltipView alloc] initWithTargetView:view
                                                         hostView:parentView
                                                      tooltipText:NSLocalizedString(@"Copy Scientific Name", @"Button to copy the scientific name")
                                                   arrowDirection:JDFTooltipViewArrowDirectionDown
                                                            width:250];
        self.tooltip.tooltipBackgroundColour = [UIColor inatTint];
        [self.tooltip addTapTarget:self action:@selector(copiedName)];
        self.tooltip.dismissOnTouch = YES;
        [self.tooltip show];
    }
}


#pragma mark - helpers

- (TaxaAPI *)taxaApi {
    static TaxaAPI *_api = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _api = [[TaxaAPI alloc] init];
    });
    return _api;
}

- (void)copiedName {
    [[UIPasteboard generalPasteboard] setString:self.fullTaxon.scientificName];
}

- (NSURL *)moreDetailsURL {
    if (self.fullTaxon) {
        NSString *taxonPath = [NSString stringWithFormat:@"/taxa/%ld", (long)self.taxonId];
        NSURL *taxonUrl = [[NSURL inat_baseURL] URLByAppendingPathComponent:taxonPath];
        NSURLComponents *urlComponents = [[NSURLComponents alloc] initWithURL:taxonUrl resolvingAgainstBaseURL:NO];
        
        // add a locale
        NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
        NSString *queryString = [NSString stringWithFormat:@"locale=%@", language];
        [urlComponents setQuery:queryString];
        
        return [urlComponents URL];
    } else {
        return nil;
    }
}

#pragma mark - UIViewController Lifecycle

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.observationCoordinate = kCLLocationCoordinate2DInvalid;
        self.showsActionButton = NO;
    }
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                           target:self
                                                                                           action:@selector(shareTapped:)];
    
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.estimatedRowHeight = 44;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    // cannot seem to do this in the storyboard
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassRegular &&
        self.traitCollection.verticalSizeClass == UIUserInterfaceSizeClassRegular) {
        
        self.tableView.tableHeaderView.frame = CGRectMake(0,
                                                          0,
                                                          self.tableView.bounds.size.width,
                                                          420);
    }
    

    self.fullTaxon = [ExploreTaxonRealm objectForPrimaryKey:@(self.taxonId)];
    
    if (self.fullTaxon) {
        self.title = self.fullTaxon.displayFirstName;
    }

    self.mapRect = MKMapRectNull;
    __weak typeof(self) weakSelf = self;
    [[self taxaApi] boundingBoxForTaxon:self.taxonId handler:^(NSArray *results, NSInteger count, NSError *error) {
        weakSelf.numberOfObservations = count;
        NSDictionary *coords = [results firstObject];
        CLLocationCoordinate2D sw = CLLocationCoordinate2DMake([[coords valueForKey:@"swlat"] floatValue],
                                                               [[coords valueForKey:@"swlng"] floatValue]);
        CLLocationCoordinate2D ne = CLLocationCoordinate2DMake([[coords valueForKey:@"nelat"] floatValue],
                                                               [[coords valueForKey:@"nelng"] floatValue]);
        
        MKMapPoint p1 = MKMapPointForCoordinate(sw);
        MKMapPoint p2 = MKMapPointForCoordinate(ne);
        
        weakSelf.mapRect = MKMapRectMake(fmin(p1.x,p2.x),
                                         fmin(p1.y,p2.y),
                                         fabs(p1.x-p2.x),
                                         fabs(p1.y-p2.y));
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.tableView reloadData];
        });
    }];
    
    [[self taxaApi] taxonWithId:self.taxonId handler:^(NSArray *results, NSInteger count, NSError *error) {
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm beginWriteTransaction];
        for (ExploreTaxon *et in results) {
            ExploreTaxonRealm *etr = [[ExploreTaxonRealm alloc] initWithMantleModel:et];
            [realm addOrUpdateObject:etr];
        }
        [realm commitWriteTransaction];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // reload the full taxon on the main thread
            weakSelf.fullTaxon = [ExploreTaxonRealm objectForPrimaryKey:@(weakSelf.taxonId)];
            weakSelf.title = self.fullTaxon.displayFirstName;
            weakSelf.photoPageVC.taxon = self.fullTaxon;
            [weakSelf.photoPageVC reloadPages];
            [weakSelf.tableView reloadData];
        });
    }];
        
    self.infoButton.clipsToBounds = YES;
    self.infoButton.layer.cornerRadius = 22.0f;
    self.infoButton.layer.borderColor = [UIColor colorWithHexString:@"#cccccc"].CGColor;
    self.infoButton.layer.borderWidth = 2.0f;
    

}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"taxonPhotoEmbed"]) {
        self.photoPageVC = segue.destinationViewController;
    } else if ([segue.identifier isEqualToString:@"map"]) {
        TaxonMapViewController *vc = (TaxonMapViewController *)segue.destinationViewController;
        vc.etr = self.fullTaxon;
        if (CLLocationCoordinate2DIsValid(self.observationCoordinate)) {
            vc.observationCoordinate = self.observationCoordinate;
        }
        if (!MKMapRectIsEmpty(self.mapRect)) {
            vc.mapRect = self.mapRect;
        }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.navigationController setToolbarHidden:YES];
    self.navigationController.navigationBar.translucent = NO;
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor inatTint];
    self.navigationItem.leftBarButtonItem.tintColor = [UIColor inatTint];
    [self.navigationItem.leftBarButtonItem setEnabled:YES];
}

#pragma mark - UITableView

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        // selector and name/wikipedia excerpt section
        if (self.showsActionButton) {
            return 2;
        } else {
            return 1;
        }
    } else {
        // map
        return 1;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (self.showsActionButton && indexPath.item == 0) {
            // selector
            TaxonSelectButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:@"selectButton"
                                                                          forIndexPath:indexPath];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;

            NSString *selectTitle = NSLocalizedString(@"Select", @"default select title");
            NSString *selectBase = NSLocalizedString(@"Select \"%@\"", @"select taxon title");

            if (self.fullTaxon) {
                selectTitle = [NSString stringWithFormat:selectBase, self.fullTaxon.displayFirstName];
            }
            [cell.button setTitle:selectTitle forState:UIControlStateNormal];
            
            return cell;
        } else {
            // name/wikipedia
            TaxonSummaryCell *cell = [tableView dequeueReusableCellWithIdentifier:@"nameInfo"
                                                                     forIndexPath:indexPath];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            if (self.fullTaxon) {
                cell.firstNameLabel.text = self.fullTaxon.displayFirstName;
                if (self.fullTaxon.displayFirstNameIsItalicized) {
                    cell.firstNameLabel.font = [UIFont italicSystemFontOfSize:cell.firstNameLabel.font.pointSize];
                }
                
                cell.secondNameLabel.text = self.fullTaxon.displaySecondName;
                if (self.fullTaxon.displaySecondNameIsItalicized) {
                    cell.secondNameLabel.font = [UIFont italicSystemFontOfSize:cell.secondNameLabel.font.pointSize];
                }
                
                cell.summaryTextView.text = nil;
            }
                        
            if (self.fullTaxon) {
                cell.summaryTextView.attributedText = [self.fullTaxon wikipediaSummaryAttrStringWithSystemFontSize:15.0f];
                [cell.summaryTextView sizeToFit];
            }

            return cell;
        }
    } else {
        // map
        TaxonMapCell *cell = [tableView dequeueReusableCellWithIdentifier:@"taxonMap"
                                                             forIndexPath:indexPath];
        // setting this in IB doesn't work
        cell.mapView.userInteractionEnabled = NO;
        cell.mapView.delegate = self;
        
        if (![[INatReachability sharedClient] isNetworkReachable]) {
            cell.mapView.hidden = YES;
            cell.noObservationsLabel.hidden = YES;
            cell.noNetworkLabel.hidden = NO;
            cell.noNetworkAlertIcon.hidden = NO;
        } else {
            cell.noNetworkLabel.hidden = YES;
            cell.noNetworkAlertIcon.hidden = YES;
            
            if (self.fullTaxon) {
                if (self.numberOfObservations == 0) {
                    cell.mapView.hidden = YES;
                    cell.noObservationsLabel.hidden = NO;
                } else {
                    cell.mapView.hidden = NO;
                    cell.noObservationsLabel.hidden = YES;
                    NSString *template = [NSString stringWithFormat:@"https://tiles.inaturalist.org/v1/colored_heatmap/{z}/{x}/{y}.png?taxon_id=%ld&verifiable=true",
                                          (long)self.taxonId];
                    MKTileOverlay *overlay = [[MKTileOverlay alloc] initWithURLTemplate:template];
                    overlay.tileSize = CGSizeMake(512, 512);
                    overlay.canReplaceMapContent = NO;
                    [cell.mapView addOverlay:overlay
                                       level:MKOverlayLevelAboveLabels];
                    if (!MKMapRectIsNull(self.mapRect)) {
                        if (CLLocationCoordinate2DIsValid(self.observationCoordinate)) {
                            // try to show both the map tiles of other observations _and_
                            // the point for the current observation
                            MKMapPoint obsPoint = MKMapPointForCoordinate(self.observationCoordinate);
                            MKMapRect obsCoordRect = MKMapRectMake(obsPoint.x,
                                                                   obsPoint.y,
                                                                   0.1,
                                                                   0.1);
                            self.mapRect = MKMapRectUnion(self.mapRect, obsCoordRect);
                        }
                        [cell.mapView setVisibleMapRect:self.mapRect
                                            edgePadding:UIEdgeInsetsMake(20, 20, 20, 20)
                                               animated:NO];
                    }
                    
                    if (CLLocationCoordinate2DIsValid(self.observationCoordinate)) {
                        MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
                        annotation.coordinate = self.observationCoordinate;
                        annotation.title = NSLocalizedString(@"Selected Observation", nil);
                        [cell.mapView addAnnotation:annotation];
                        if (!MKMapRectContainsPoint([cell.mapView visibleMapRect], MKMapPointForCoordinate(self.observationCoordinate))) {
                            [cell.mapView setCenterCoordinate:self.observationCoordinate];
                        }
                    }
                }
            }
        }
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 1) {
        [self performSegueWithIdentifier:@"map" sender:nil];
    } else if (indexPath.section == 0) {
        if ((self.showsActionButton && indexPath.item == 1) || (!self.showsActionButton)) {
            TaxonSummaryCell *cell = (TaxonSummaryCell *)[tableView cellForRowAtIndexPath:indexPath];
            [self toggleTooltipInView:cell.secondNameLabel parentView:cell.contentView];
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        return NSLocalizedString(@"Map of Observations", nil);
    } else {
        return nil;
    }
}

#pragma mark - MKMapViewDelegate

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id <MKOverlay>)overlay {
    return [[MKTileOverlayRenderer alloc] initWithTileOverlay:overlay];
}

- (MKAnnotationView *)mapView:(MKMapView *)map viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    static NSString *const AnnotationViewReuseID = @"ObservationAnnotationMarkerReuseID";
    
    MKAnnotationView *annotationView = [map dequeueReusableAnnotationViewWithIdentifier:AnnotationViewReuseID];
    if (!annotationView) {
        annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation
                                                      reuseIdentifier:AnnotationViewReuseID];
        annotationView.canShowCallout = NO;
    }
    
    // style for iconic taxon of the observation
    FAKIcon *mapMarker = [FAKIonIcons iosLocationIconWithSize:25.0f];
    [mapMarker addAttribute:NSForegroundColorAttributeName value:[UIColor colorForIconicTaxon:self.fullTaxon.iconicTaxonName]];
    FAKIcon *mapOutline = [FAKIonIcons iosLocationOutlineIconWithSize:25.0f];
    [mapOutline addAttribute:NSForegroundColorAttributeName value:[[UIColor colorForIconicTaxon:self.fullTaxon.iconicTaxonName] darkerColor]];
    
    // offset the marker so that the point of the pin (rather than the center of the glyph) is at the location of the observation
    [mapMarker addAttribute:NSBaselineOffsetAttributeName value:@(25.0f)];
    [mapOutline addAttribute:NSBaselineOffsetAttributeName value:@(25.0f)];
    annotationView.image = [UIImage imageWithStackedIcons:@[mapMarker, mapOutline] imageSize:CGSizeMake(25.0f, 50.0f)];
    
    return annotationView;
}


@end

#pragma mark -
@implementation INatCopyNameActivity


- (UIActivityType)activityType {
    return @"org.inaturalist.copyname";
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    for (id item in activityItems) {
        if ([item isKindOfClass:[NSString class]]) {
            return YES;
        }
    }
    return NO;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    for (id item in activityItems) {
        if ([item isKindOfClass:[NSString class]]) {
            self.inatName = (NSString *)item;
            break;
        }
    }
}

- (void)performActivity {
    if (self.inatName) {
        [[UIPasteboard generalPasteboard] setString:self.inatName];
    }
}

- (NSString *)activityTitle {
    return NSLocalizedString(@"Copy Scientific Name", @"Button to copy the scientific name");
}

@end
