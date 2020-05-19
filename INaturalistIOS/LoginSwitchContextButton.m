//
//  LoginSwitchContextButton.m
//  iNaturalist
//
//  Created by Alex Shepard on 3/26/18.
//  Copyright © 2018 iNaturalist. All rights reserved.
//

@import UIColor_HTMLColors;

#import "LoginSwitchContextButton.h"

@implementation LoginSwitchContextButton

- (void)awakeFromNib {
    [super awakeFromNib];
    
    // always default to signup context
    [self setContext:LoginContextSignup];
    
    self.tintColor = [UIColor colorWithHexString:@"#4a4a4a"];
}

- (void)setContext:(LoginContext)context {
    NSAttributedString *attributedTitle = [self attributedTitleForContext:context];
    [self setAttributedTitle:attributedTitle forState:UIControlStateNormal];
}

- (NSAttributedString *)attributedTitleForContext:(LoginContext)context {
    
    NSString *baseString = [self baseStringForContext:context];
    NSDictionary *baseAttrs = @{
                                NSFontAttributeName: [UIFont systemFontOfSize:15]
                                };
    
    NSString *emphasisString = [self emphasisStringForContext:context];
    NSDictionary *emphasisAttrs = @{
                                    NSFontAttributeName: [UIFont boldSystemFontOfSize:15]
                                    };

    NSMutableAttributedString *contextAttrStr = [[NSMutableAttributedString alloc] initWithString:baseString
                                                                                       attributes:baseAttrs];
    NSRange emphasisRange = [baseString rangeOfString:emphasisString];
    if (emphasisRange.location != NSNotFound) {
        [contextAttrStr addAttributes:emphasisAttrs range:emphasisRange];
    }
    
    // return immutable copy
    return [[NSAttributedString alloc] initWithAttributedString:contextAttrStr];
}

- (NSString *)baseStringForContext:(LoginContext)context {
    if (context == LoginContextLogin) {
        // if the context is login, the switch context call will be to sign up
        return NSLocalizedString(@"New to iNaturalist? Sign up now!", @"base text for the 'switch to signup mode' button");
    } else {
        return NSLocalizedString(@"Already have an Account?", @"base text for the 'switch to login mode' button");
    }

}

- (NSString *)emphasisStringForContext:(LoginContext)context {
    if (context == LoginContextLogin) {
        return NSLocalizedString(@"Sign up now!", @"emphasis text for the 'switch to signup mode' button. must be a substring of the base text");
    } else {
        return NSLocalizedString(@"Account?", @"emphasis text for the 'switch to login mode' button. must be a substring of the base text");
    }
}


@end
