//
//  ObsDetailInfoViewModel.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/18/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

@import MapKit;

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
        
        cell.textLabel.text = nil;
        cell.detailTextLabel.text = nil;
        
        if (self.observation.latitude.floatValue) {
            MKMapView *mv = [[MKMapView alloc] initWithFrame:cell.bounds];
            mv.mapType = MKMapTypeHybrid;
            mv.userInteractionEnabled = NO;
            mv.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
            
            CLLocationCoordinate2D coords = CLLocationCoordinate2DMake(self.observation.latitude.floatValue, self.observation.longitude.floatValue);
            CLLocationDistance distance = self.observation.positionalAccuracy.integerValue ?: 500;
            mv.region = MKCoordinateRegionMakeWithDistance(coords, distance, distance);
            
            [cell.contentView addSubview:mv];
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
        case 3:
            return NSLocalizedString(@"More Info", @"Header for more info section of obs detail");
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
        case 3:
            return 34;
            break;
        case 2:
            return 2;
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
            return 120;
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
    } else if (section == 3) {
        return 2;
    } else {
        return 0;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (ObsDetailSection)sectionType {
    return ObsDetailSectionInfo;
}

@end
