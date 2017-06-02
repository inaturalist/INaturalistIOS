//
//  TaxonMapCell.h
//  iNaturalist
//
//  Created by Alex Shepard on 5/23/17.
//  Copyright © 2017 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@import MapKit;

@interface TaxonMapCell : UITableViewCell
@property IBOutlet MKMapView *mapView;
@property IBOutlet UILabel *noObservationsLabel;
@property IBOutlet UILabel *noNetworkLabel;
@property IBOutlet UILabel *noNetworkAlertIcon;
@end
