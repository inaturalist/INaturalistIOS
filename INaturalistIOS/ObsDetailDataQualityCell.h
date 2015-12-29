//
//  ObsDetailDataQualityCell.h
//  iNaturalist
//
//  Created by Alex Shepard on 12/15/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, ObsDataQuality) {
    ObsDataQualityCasual,
    ObsDataQualityNeedsID,
    ObsDataQualityResearch,
    ObsDataQualityNone
};

@interface ObsDetailDataQualityCell : UITableViewCell

@property ObsDataQuality dataQuality;

@end
