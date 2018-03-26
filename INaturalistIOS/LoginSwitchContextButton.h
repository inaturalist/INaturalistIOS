//
//  LoginSwitchContextButton.h
//  iNaturalist
//
//  Created by Alex Shepard on 3/26/18.
//  Copyright © 2018 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, LoginContext) {
    LoginContextSignup,
    LoginContextLogin
};

@interface LoginSwitchContextButton : UIButton
- (void)setContext:(LoginContext)context;
@end
