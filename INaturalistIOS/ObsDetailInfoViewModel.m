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

@implementation ObsDetailInfoViewModel

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.item < 4) {
            return [super tableView:tableView cellForRowAtIndexPath:indexPath];
        } else if (indexPath.item == 4) {
            // notes
            
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"subtitle"];
            
            // what if there are no notes?
            cell.textLabel.text = NSLocalizedString(@"Notes", @"notes for obs detail");
            cell.detailTextLabel.text = self.observation.inatDescription;
            cell.detailTextLabel.numberOfLines = 0;
            
            return cell;
        } else if (indexPath.item == 5) {
            // data quality
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"subtitle"];
            cell.textLabel.text = NSLocalizedString(@"DATA QUALITY", @"data quality notes");
            cell.detailTextLabel.text = self.observation.qualityGrade ?: @"Needs ID";
            
            return cell;
        }
    } else if (indexPath.section == 1) {
        // map
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"subtitle"];
        cell.backgroundColor = [UIColor lightGrayColor];
        
        cell.textLabel.text = nil;
        cell.detailTextLabel.text = nil;
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        if (self.observation.latitude.floatValue) {
            MKMapView *mv = [[MKMapView alloc] initWithFrame:cell.bounds];
            mv.mapType = MKMapTypeHybrid;
            mv.userInteractionEnabled = NO;
            mv.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
            
            CLLocationCoordinate2D coords = CLLocationCoordinate2DMake(self.observation.latitude.floatValue, self.observation.longitude.floatValue);
            CLLocationDistance distance = self.observation.positionalAccuracy.integerValue ?: 500;
            mv.region = MKCoordinateRegionMakeWithDistance(coords, distance, distance);
            
            MKPointAnnotation *pin = [[MKPointAnnotation alloc] init];
            pin.coordinate = coords;
            pin.title = @"Title";
            [mv addAnnotation:pin];
            
            [cell.contentView addSubview:mv];
            
        }

        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, cell.bounds.size.width - 20, 30)];
        label.layer.cornerRadius = 3.0f;
        label.clipsToBounds = YES;
        label.backgroundColor = [UIColor whiteColor];
        label.textColor = [UIColor grayColor];
        label.font = [UIFont systemFontOfSize:12.0f];
        label.textAlignment = NSTextAlignmentCenter;
        
        [cell.contentView addSubview:label];

        if (self.observation.placeGuess && self.observation.placeGuess.length > 0) {
            label.text = self.observation.placeGuess;
        } else {
            label.text = NSLocalizedString(@"No location.", nil);
        }

        
        return cell;
        
    } else if (indexPath.section == 2) {
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
            return [super tableView:tableView titleForHeaderInSection:section];
            break;
        case 1:
            return NSLocalizedString(@"Location", @"Header for location section of obs detail");
            break;
        case 2:
            return nil;
            break;
        default:
            return nil;
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return [super tableView:tableView heightForHeaderInSection:section];
            break;
        case 1:
        case 2:
        case 3:
            return 34;
            break;
        default:
            return 0;
            break;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row < 4) {
            return [super tableView:tableView heightForRowAtIndexPath:indexPath];
        } else if (indexPath.row == 4) {
            // notes
            if (self.observation.inatDescription && self.observation.inatDescription.length > 0) {
                return 120;
            } else {
                return CGFLOAT_MIN;
            }
        } else {
            return 44;
        }
    } else if (indexPath.section == 1) {
        // location
        return 120;
    } else {
        return 44;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 6;
    } else if (section == 1) {
        return 1;
    } else if (section == 2) {
        return 1;
    } else {
        return 0;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.item == 1) {
        // show the full screen photo
    } else if (indexPath.section == 1) {
        // show the map view
    } else if (indexPath.section == 2) {
        if (self.observation.projectObservations.count > 0) {
            // show the projects screen
            [self.delegate inat_performSegueWithIdentifier:@"projects"];
        }
    }
}

#pragma mark - section type helper

- (ObsDetailSection)sectionType {
    return ObsDetailSectionInfo;
}

@end
