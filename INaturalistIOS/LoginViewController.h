//
//  LoginViewController.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/17/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SplitTextButton;
@class Partner;

@interface LoginViewController : UIViewController

@property UIImage *backgroundImage;
@property BOOL cancellable;
@property UITableView *loginTableView;
@property SplitTextButton *gButton, *faceButton;
@property UILabel *orLabel;
@property Partner *selectedPartner;
@end
