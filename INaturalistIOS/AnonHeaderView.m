//
//  AnonHeaderView.m
//  iNaturalist
//
//  Created by Alex Shepard on 1/8/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

#import "AnonHeaderView.h"
#import "UIColor+INaturalist.h"

@interface AnonHeaderView ()
@property IBOutlet UILabel *anonPrompt;
@end

@implementation AnonHeaderView

- (void)awakeFromNib {
    [super awakeFromNib];
    
    self.backgroundColor = [UIColor inatDarkGray];

    self.anonPrompt.font = [UIFont systemFontOfSize:15];
    self.anonPrompt.textColor = [UIColor whiteColor];
    self.anonPrompt.numberOfLines = 0;
    self.anonPrompt.textAlignment = NSTextAlignmentCenter;
    self.anonPrompt.text = NSLocalizedString(@"Share your observations with the community.",
                                   @"Prompt to sign in on the Me tab header.");
    
    self.loginButton.tintColor = [UIColor inatTint];
    self.loginButton.backgroundColor = [UIColor whiteColor];
    self.loginButton.titleLabel.font = [UIFont boldSystemFontOfSize:self.loginButton.titleLabel.font.pointSize];
    
    self.loginButton.layer.cornerRadius = 17.0f;

    [self.loginButton setTitle:NSLocalizedString(@"Log In", @"Title for button that allows users to log in to their existing iNat account")
                      forState:UIControlStateNormal];
    
    
    self.signupButton.tintColor = [UIColor inatTint];
    self.signupButton.backgroundColor = [UIColor whiteColor];
    self.signupButton.titleLabel.font = [UIFont boldSystemFontOfSize:self.signupButton.titleLabel.font.pointSize];
    
    self.signupButton.layer.cornerRadius = 17.0f;
    
    [self.signupButton setTitle:NSLocalizedString(@"Sign Up", @"Title for button that allows users to sign up for a new iNat account")
                       forState:UIControlStateNormal];


    
}

@end
