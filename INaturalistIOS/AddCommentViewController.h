//
//  AddCommentViewController.h
//  iNaturalist
//
//  Created by Ryan Waggoner on 10/23/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ObservationVisualization.h"

@interface AddCommentViewController : UIViewController

@property (nonatomic, strong) id <ObservationVisualization> observation;

@end
