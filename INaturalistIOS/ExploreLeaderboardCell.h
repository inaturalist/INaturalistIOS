//
//  ExploreLeaderboardCell.h
//  iNaturalist
//
//  Created by Alex Shepard on 2/18/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ExploreLeaderboardCell : UITableViewCell

@property UILabel *rank;
@property UIImageView *userIcon;
@property UILabel *username;
@property UILabel *observationCount;
@property UILabel *speciesCount;
@property UIControl *sortControl;

@end
