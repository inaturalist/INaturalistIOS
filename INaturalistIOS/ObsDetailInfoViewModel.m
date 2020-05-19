//
//  ObsDetailInfoViewModel.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/18/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

@import MapKit;
@import FontAwesomeKit;
@import UIColor_HTMLColors;

#import "ObsDetailInfoViewModel.h"
#import "Observation.h"
#import "DisclosureCell.h"
#import "ObsDetailMapCell.h"
#import "UIColor+ExploreColors.h"
#import "ObsDetailNotesCell.h"
#import "ObsDetailDataQualityCell.h"
#import "ObsDetailQualityDetailsFooter.h"
#import "FAKINaturalist.h"
#import "Analytics.h"
#import "UIImage+MapAnnotations.h"
#import "iNaturalist-Swift.h"

@interface ObsDetailInfoViewModel () <MKMapViewDelegate>
@end

@implementation ObsDetailInfoViewModel

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    static NSString *const AnnotationViewReuseID = @"ObservationAnnotationMarkerReuseID";
    
    MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:AnnotationViewReuseID];
    if (!annotationView) {
        annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation
                                                      reuseIdentifier:AnnotationViewReuseID];
        annotationView.canShowCallout = NO;
    }
    
    annotationView.image = [UIImage annotationImageForObservation:self.observation];

    return annotationView;
}

- (void)mapView:(MKMapView *)map didSelectAnnotationView:(MKAnnotationView *)view {
    // do nothing
    return;
}


#pragma mark - UITableView delegate/datasource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < 2) {
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    } else if (indexPath.section == 2) {
        if (self.observation.inatDescription.length == 0 || indexPath.item == 1) {
            // map
            ObsDetailMapCell *cell = [tableView dequeueReusableCellWithIdentifier:@"map"];
            cell.mapView.delegate = self;
            cell.mapView.userInteractionEnabled = NO;
            
            CLLocationCoordinate2D coords = [self.observation visibleLocation];
            
            if (CLLocationCoordinate2DIsValid(coords)) {
                // latitude at 90 or -90 is legal on the server, and a legal coordinate,
                // but is super problematic and needs to be nudged.
                // spans with a center latitude at 90 or -90 produce MKCoordinateRegions
                // map distinces of infinity in the x coordinate
                
                if (coords.latitude == 90) {
                    coords = CLLocationCoordinate2DMake(89.999, coords.longitude);
                } else if (coords.latitude == -90) {
                    coords = CLLocationCoordinate2DMake(-89.999, coords.longitude);
                }
                
                cell.mapView.hidden = NO;
                cell.noLocationLabel.hidden = YES;
                
                CLLocationDistance distance;
                if ([self.observation visiblePositionalAccuracy] == 0) {
                    distance = 500;
                } else {
                    distance = MAX([self.observation visiblePositionalAccuracy], 200);
                }
                
                @try {
                    cell.mapView.region = MKCoordinateRegionMakeWithDistance(coords, distance, distance);
                } @catch (NSException *exception) {
                    if (exception.name == NSInvalidArgumentException) {
                        // invalid region, just set the center
                        cell.mapView.centerCoordinate = coords;
                    } else {
                        @throw exception;
                    }
                }
                
                MKPointAnnotation *pin = [[MKPointAnnotation alloc] init];
                pin.coordinate = coords;
                pin.title = @"Title";
                [cell.mapView addAnnotation:pin];
                
                if (self.observation.placeGuess && self.observation.placeGuess.length > 0) {
                    cell.locationNameLabel.text = self.observation.placeGuess;
                } else {
                    NSString *positionalAccuracy = nil;
                    if ([self.observation visiblePositionalAccuracy] != 0) {
                        positionalAccuracy = [NSString stringWithFormat:@"%ld m", (long)[self.observation visiblePositionalAccuracy]];
                    } else {
                        positionalAccuracy = NSLocalizedString(@"???", @"positional accuracy when we don't know");
                    }
                    
                    NSString *baseStr = NSLocalizedString(@"Lat: %.5f Long: %.5f Acc: %@", @"visualization of latitude/longitude/accuracy");
                    NSString *subtitleString = [NSString stringWithFormat:baseStr,
                                                coords.latitude,
                                                coords.longitude,
                                                positionalAccuracy];
                    cell.locationNameLabel.text = subtitleString;
                }
            } else {
                cell.mapView.hidden = YES;
                cell.noLocationLabel.hidden = NO;
            }
            
            if ([self.observation.geoprivacy isEqualToString:@"private"]) {
                cell.geoprivacyLabel.attributedText = ({
                    FAKIcon *private = [FAKINaturalist icnLocationPrivateIconWithSize:24];
                    [private addAttribute:NSForegroundColorAttributeName
                                    value:[UIColor lightGrayColor]];
                    private.attributedString;
                });
            } else if ([self.observation.geoprivacy isEqualToString:@"obscured"] || [self.observation coordinatesObscuredToUser]) {
                cell.geoprivacyLabel.attributedText = ({
                    FAKIcon *obscured = [FAKINaturalist icnLocationObscuredIconWithSize:24];
                    [obscured addAttribute:NSForegroundColorAttributeName
                                     value:[UIColor lightGrayColor]];
                    obscured.attributedString;
                });
            } else {
                cell.geoprivacyLabel.text = nil;
            }
            return cell;
        } else {
            // notes
            ObsDetailNotesCell *cell = [tableView dequeueReusableCellWithIdentifier:@"notes"];
            cell.notesTextView.dataDetectorTypes = UIDataDetectorTypeLink;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
                        
            NSString *path = [[NSBundle mainBundle] pathForResource:@"bootstrap" ofType:@"min.css"];
            NSError *error = nil;
            NSString *css = [NSString stringWithContentsOfFile:path
                                                      encoding:kCFStringEncodingUTF8
                                                         error:&error];
            DownWrapper *dw = [[DownWrapper alloc] init];
            NSAttributedString *attrStr = [dw markdownToAttributedStringWithMarkdownStr:self.observation.inatDescription
                                                                                    css:css];
            cell.notesTextView.attributedText = attrStr;
            
            return cell;
        }
    } else if (indexPath.section == 3) {
        // data quality
        ObsDetailDataQualityCell *cell = [tableView dequeueReusableCellWithIdentifier:@"dataQuality"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.dataQuality = self.observation.dataQuality;
        
        return cell;
    }
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"rightDetail"];
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
        case 1:
            return [super tableView:tableView titleForHeaderInSection:section];
            break;
        case 3:
            // data quality
            return NSLocalizedString(@"Data Quality", @"Header for data quality section of obs detail");
            break;
        case 2:     // notes/map - no header
        default:
            return nil;
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
        case 1:
            return [super tableView:tableView heightForHeaderInSection:section];
            break;
        case 3:
            // data quality
            return 44;
        case 2:
        default:
            return 0;
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section < 2) {
        return [super tableView:tableView heightForFooterInSection:section];
    } else if (section == 3) {
        // data quality
        if (self.observation.dataQuality == ObsDataQualityResearch) {
            return CGFLOAT_MIN;
        } else if (!self.observation.inatRecordId) {
            return CGFLOAT_MIN;
        } else {
            return 66;
        }
    } else {
        return CGFLOAT_MIN;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section < 2) {
        return [super tableView:tableView viewForFooterInSection:section];
    } else if (section == 3) {
        // data quality
        if (self.observation.dataQuality == ObsDataQualityResearch) {
            return nil;
        } else if (!self.observation.inatRecordId) {
            return nil;
        } else {
            ObsDetailQualityDetailsFooter *footer = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"qualityDetails"];

            if (self.observation.dataQuality == ObsDataQualityNeedsID) {
                if (self.observation.identifications.count < 2) {
                    footer.dataQualityDetails = NSLocalizedString(@"This observation needs more IDs from the iNat community to be considered for Research Grade.", nil);
                } else {
                    footer.dataQualityDetails = NSLocalizedString(@"This observation needs a more specific consensus ID to be considered for Research Grade.", nil);
                }
            } else if (self.observation.dataQuality == ObsDataQualityCasual) {
                if (self.observation.observationPhotos.count == 0) {
                    footer.dataQualityDetails = NSLocalizedString(@"This observation needs a photo to be considered for Research Grade.", nil);
                } else if (!CLLocationCoordinate2DIsValid([self.observation visibleLocation])) {
                    footer.dataQualityDetails = NSLocalizedString(@"This observation needs a location to be considered for Research Grade.", nil);
                } else if (!self.observation.observedOn) {
                    footer.dataQualityDetails = NSLocalizedString(@"This observation needs a date to be considered for Research Grade.", nil);
                } else if (self.observation.isCaptive) {
                    footer.dataQualityDetails = NSLocalizedString(@"This observation is Casual Grade because it has been voted captive or cultivated by the iNaturalist community.", nil);
                } else {
                    footer.dataQualityDetails = NSLocalizedString(@"This observation has been voted as Casual Grade by the iNaturalist community.", nil);
                }
            } else {
                footer.dataQualityDetails = nil;
            }
            
            return footer;
        }

    } else {
        return nil;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section < 2) {
        return [super tableView:tableView numberOfRowsInSection:section];
    } else if (section == 2) {
        // notes/map
        if (self.observation.inatDescription.length > 0) {
            return 2;
        } else {
            return 1;
        }
    } else if (section == 3) {
        // data quality
        return 1;
    } else {
        return 0;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // notes/map, data quality
    NSInteger numSections = [super numberOfSectionsInTableView:tableView] + 2;
    return numSections;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < 2) {
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    } else if (indexPath.section == 2) {
        // notes / map
        if (self.observation.inatDescription.length == 0 || indexPath.item == 1) {
            // map
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            
            CLLocationCoordinate2D coords = [self.observation visibleLocation];
            
            if (CLLocationCoordinate2DIsValid(coords)) {
                // show the map view
                [self.delegate inat_performSegueWithIdentifier:@"map" sender:nil];
            }
        }
    } else if (indexPath.section == 3) {
        // data quality, do nothing
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        if (self.observation.dataQuality == ObsDataQualityNone) {
            NSURL *dataQualityURL = [NSURL URLWithString:@"https://www.inaturalist.org/pages/help#quality"];
            if (dataQualityURL) {
                [[UIApplication sharedApplication] openURL:dataQualityURL];
            }
        }
    }
}

#pragma mark - section type helper

- (ObsDetailSection)sectionType {
    return ObsDetailSectionInfo;
}

@end
