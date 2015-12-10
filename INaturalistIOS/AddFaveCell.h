//
//  AddFaveCell.h
//  iNaturalist
//
//  Created by Alex Shepard on 11/21/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AddFaveCell : UITableViewCell

@property IBOutlet UIView *faveContainer;

@property IBOutlet UILabel *starLabel;
@property IBOutlet UILabel *faveActionLabel;
@property IBOutlet UILabel *faveCountLabel;

@property BOOL faved;

@end
