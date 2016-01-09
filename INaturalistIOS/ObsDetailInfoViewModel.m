//
//  ObsDetailInfoViewModel.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/18/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

@import MapKit;

#import <FontAwesomeKit/FAKIonIcons.h>
#import <UIColor-HTMLColors/UIColor+HTMLColors.h>

#import "ObsDetailInfoViewModel.h"
#import "Observation.h"
#import "DisclosureCell.h"
#import "ObsDetailMapCell.h"
#import "UIColor+ExploreColors.h"
#import "ObsDetailNotesCell.h"
#import "ObsDetailDataQualityCell.h"
#import "ObsDetailQualityDetailsFooter.h"

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
    
    // style for iconic taxon of the observation
    FAKIcon *mapMarker = [FAKIonIcons iosLocationIconWithSize:35.0f];
    [mapMarker addAttribute:NSForegroundColorAttributeName value:[UIColor colorForIconicTaxon:self.observation.iconicTaxonName]];
    FAKIcon *mapOutline = [FAKIonIcons iosLocationOutlineIconWithSize:35.0f];
    [mapOutline addAttribute:NSForegroundColorAttributeName value:[[UIColor colorForIconicTaxon:self.observation.iconicTaxonName] darkerColor]];
    
    annotationView.image = [UIImage imageWithStackedIcons:@[mapMarker, mapOutline] imageSize:CGSizeMake(35.0f, 70)];
    
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
        if (indexPath.item == 0) {
            // notes
            ObsDetailNotesCell *cell = [tableView dequeueReusableCellWithIdentifier:@"notes"];
            cell.notesTextView.dataDetectorTypes = UIDataDetectorTypeLink;
            
            NSError *err;
            NSMutableAttributedString *notes = [[[NSAttributedString alloc] initWithData:[self.observation.inatDescription dataUsingEncoding:NSUTF8StringEncoding]
                                                                                 options:@{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType }
                                                                      documentAttributes:nil
                                                                                   error:&err] mutableCopy];
            
            // reading this as HTML gives it a with-serif font
            [notes addAttribute:NSFontAttributeName
                          value:[UIFont systemFontOfSize:14]
                          range:NSMakeRange(0, notes.length)];
            
            cell.notesTextView.attributedText = notes;
            
            return cell;
        } else if (indexPath.item == 1) {
            // map
            ObsDetailMapCell *cell = [tableView dequeueReusableCellWithIdentifier:@"map"];
            cell.mapView.delegate = self;
            cell.mapView.userInteractionEnabled = NO;
            
            if (self.observation.latitude.floatValue) {
                cell.mapView.hidden = NO;
                cell.noLocationLabel.hidden = YES;
                
                CLLocationCoordinate2D coords = CLLocationCoordinate2DMake(self.observation.latitude.floatValue, self.observation.longitude.floatValue);
                CLLocationDistance distance = self.observation.positionalAccuracy.integerValue ?: 500;
                cell.mapView.region = MKCoordinateRegionMakeWithDistance(coords, distance, distance);
                
                MKPointAnnotation *pin = [[MKPointAnnotation alloc] init];
                pin.coordinate = coords;
                pin.title = @"Title";
                [cell.mapView addAnnotation:pin];
            } else {
                cell.mapView.hidden = YES;
                cell.noLocationLabel.hidden = NO;
            }
            
            if (self.observation.placeGuess && self.observation.placeGuess.length > 0) {
                cell.locationNameLabel.text = self.observation.placeGuess;
            } else {
                cell.locationNameLabel.text = NSLocalizedString(@"No location.", nil);
            }
            
            return cell;
        }
    } else if (indexPath.section == 3) {
        // data quality
        ObsDetailDataQualityCell *cell = [tableView dequeueReusableCellWithIdentifier:@"dataQuality"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.dataQuality = self.observation.dataQuality;
        
        return cell;
    
    } else if (indexPath.section == 4) {
        // projects
        DisclosureCell *cell = [tableView dequeueReusableCellWithIdentifier:@"disclosure"];
        
        cell.titleLabel.text = NSLocalizedString(@"Projects", nil);
        FAKIcon *project = [FAKIonIcons iosBriefcaseOutlineIconWithSize:44];
        [project addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#777777"]];
        cell.cellImageView.image = [project imageWithSize:CGSizeMake(44, 44)];
        
        cell.secondaryLabel.text = [NSString stringWithFormat:@"%ld", (unsigned long)self.observation.projectObservations.count];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        if (self.observation.projectObservations.count > 0) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
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
        case 4:     // projects - no header
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
        case 4:
            // projects
            return 34;
            break;
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
        if ([self.observation.qualityGrade isEqualToString:@"research"]) {
            return CGFLOAT_MIN;
        } else if (!self.observation.recordID) {
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
        if ([self.observation.qualityGrade isEqualToString:@"research"]) {
            return nil;
        } else if (!self.observation.recordID) {
            return nil;
        } else {
            ObsDetailQualityDetailsFooter *footer = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"qualityDetails"];

            if (self.observation.dataQuality == ObsDataQualityNeedsID) {
                if (self.observation.identificationsCount.integerValue < 2) {
                    footer.dataQualityDetails = NSLocalizedString(@"This observation needs more IDs from the iNat community to be considered for Research Grade.", nil);
                } else {
                    footer.dataQualityDetails = NSLocalizedString(@"This observation needs a more specific consensus ID to be considered for Research Grade.", nil);
                }
            } else if (self.observation.dataQuality == ObsDataQualityCasual) {
                if (self.observation.observationPhotos.count == 0) {
                    footer.dataQualityDetails = NSLocalizedString(@"This observation needs a photo to be considered for Research Grade.", nil);
                } else if (!self.observation.latitude) {
                    footer.dataQualityDetails = NSLocalizedString(@"This observation needs a location to be considered for Research Grade.", nil);
                } else if (!self.observation.observedOn) {
                    footer.dataQualityDetails = NSLocalizedString(@"This observation needs a date to be considered for Research Grade.", nil);
                } else if (self.observation.captive.boolValue) {
                    footer.dataQualityDetails = NSLocalizedString(@"This observation is Casual Grade because it has been voted captive or cultivated by the iNaturalist community.", nil);
                } else {
                    footer.dataQualityDetails = NSLocalizedString(@"This observation was voted off the island by the iNaturalist community.", nil);
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < 2) {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    } else if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            // notes
            if (self.observation.inatDescription && self.observation.inatDescription.length > 0) {
                return [self heightForRowInTableView:tableView withBodyText:self.observation.inatDescription];
            } else {
                return CGFLOAT_MIN;
            }
        } else if (indexPath.row == 1) {
            // maps
            return 180;
        }
    } else if (indexPath.section == 3) {
        // data quality
        return 80;
    } else if (indexPath.section == 4) {
        // projects
        return 44;
    }
    
    return CGFLOAT_MIN;
}

- (CGFloat)heightForRowInTableView:(UITableView *)tableView withBodyText:(NSString *)text {
    // 30 for some padding on the left/right
    CGFloat usableWidth = tableView.bounds.size.width - 30;
    CGSize maxSize = CGSizeMake(usableWidth, CGFLOAT_MAX);
    UIFont *font = [UIFont systemFontOfSize:14.0f];
    
    CGRect textRect = [text boundingRectWithSize:maxSize
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:@{ NSFontAttributeName: font }
                                         context:nil];
    
    // 22 for notes padding above and below
    return MAX(44, textRect.size.height + 22);
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section < 2) {
        return [super tableView:tableView numberOfRowsInSection:section];
    } else if (section == 2) {
        // notes/map
        return 2;
    } else if (section == 3 || section == 4) {
        // data quality, projects
        return 1;
    } else {
        return 0;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // notes/map, data quality
    NSInteger numSections = [super numberOfSectionsInTableView:tableView] + 2;
    
    if (self.observation.projectObservations.count > 0) {
        // show projects section
        numSections++;
    }
    
    return numSections;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < 2) {
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    } else if (indexPath.section == 2) {
        // notes / map
        if (indexPath.item == 1) {
            // map
            // map
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            
            if (self.observation.latitude) {
                // show the map view
                [self.delegate inat_performSegueWithIdentifier:@"map" sender:nil];
            }
        }
    } else if (indexPath.section == 3) {
        // data quality, do nothing
    } else if (indexPath.section == 4) {
        // projects
        if (self.observation.projectObservations.count > 0) {
            [self.delegate inat_performSegueWithIdentifier:@"projects" sender:nil];
        }
    }
}

#pragma mark - section type helper

- (ObsDetailSection)sectionType {
    return ObsDetailSectionInfo;
}

@end
