//
//  ObserverCountCell.h
//  iNaturalist
//
//  Created by Alex Shepard on 2/23/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ObserverCountCell : UITableViewCell

@property IBOutlet UIImageView *observerImageView;
@property IBOutlet UILabel *observerNameLabel;
@property IBOutlet UILabel *observerObservationsCountLabel;
@property IBOutlet UILabel *observerSpeciesCountLabel;
@property IBOutlet UILabel *rankLabel;

@end
