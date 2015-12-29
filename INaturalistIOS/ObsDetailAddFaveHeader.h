//
//  AddFaveCell.h
//  iNaturalist
//
//  Created by Alex Shepard on 11/21/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ObsDetailAddFaveHeader : UITableViewHeaderFooterView

@property UIControl *faveContainer;

@property BOOL faved;
@property NSInteger faveCount;

@end
