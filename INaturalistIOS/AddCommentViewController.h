//
//  AddCommentViewController.h
//  iNaturalist
//
//  Created by Ryan Waggoner on 10/23/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Observation;

@interface AddCommentViewController : UIViewController

@property (nonatomic, strong) Observation *observation;

@end
