//
//  SignupViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 5/15/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <FontAwesomeKit/FAKIonIcons.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <SVProgressHUD/SVProgressHUD.h>

#import "SignupViewController.h"
#import "UIColor+INaturalist.h"
#import "EditableTextFieldCell.h"
#import "INaturalistAppDelegate.h"
#import "LoginController.h"
#import "RoundedButtonCell.h"
#import "CheckboxCell.h"
#import "NSAttributedString+InatHelpers.h"
#import "UITapGestureRecognizer+InatHelpers.h"

@interface SignupViewController () <UITableViewDataSource, UITableViewDelegate> {
    NSString *email, *password, *username;
    BOOL shareData;
}
@end

@implementation SignupViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        self.title = NSLocalizedString(@"Sign Up", @"Title of the iNaturalist sign up form screen");
    }
    
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    
    [self.navigationController setNavigationBarHidden:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.automaticallyAdjustsScrollViewInsets = YES;
    
    UIImageView *background = ({
        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectZero];
        iv.translatesAutoresizingMaskIntoConstraints = NO;
        
        iv.image = self.backgroundImage;
        
        iv;
    });
    [self.view addSubview:background];
    
    
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1) {
        UIVisualEffectView *blurView = ({
            UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
            
            UIVisualEffectView *view = [[UIVisualEffectView alloc] initWithEffect:blur];
            view.frame = self.view.bounds;
            view.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
            
            view;
        });
        [self.view addSubview:blurView];
    } else {
        UIView *scrim = ({
            UIView *view = [[UIView alloc] initWithFrame:self.view.bounds];
            view.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
            
            view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6f];
            
            view;
        });
        [self.view addSubview:scrim];
    }
    
    self.signupTableView = ({
        UITableView *tv = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        tv.translatesAutoresizingMaskIntoConstraints = NO;
        
        tv.backgroundColor = [UIColor clearColor];
        tv.separatorColor = [UIColor clearColor];
        
        tv.dataSource = self;
        tv.delegate = self;
        [tv registerClass:[EditableTextFieldCell class] forCellReuseIdentifier:@"EditableText"];
        [tv registerClass:[RoundedButtonCell class] forCellReuseIdentifier:@"Button"];
        [tv registerClass:[CheckboxCell class] forCellReuseIdentifier:@"Checkbox"];
        
        tv.tableHeaderView = ({
            UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 1, 40)];
            
            view;
        });
        
        tv;
    });
    [self.view addSubview:self.signupTableView];
    
    self.termsLabel = ({
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.translatesAutoresizingMaskIntoConstraints = NO;

        label.numberOfLines = 0;
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = [UIColor whiteColor];
        
        NSString *base = NSLocalizedString(@"By using iNaturalist you agree to the Terms of Service and Privacy Policy.", @"Base text for terms of service and privacy policy notice when creating an iNat account.");
        NSString *terms = NSLocalizedString(@"Terms of Service", @"Emphasized part of the terms of service base text.");
        NSString *privacy = NSLocalizedString(@"Privacy Policy", @"Emphasized part of the privacy base text.");
        
        NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:base
                                                                                 attributes:@{
                                                                                              NSFontAttributeName: [UIFont systemFontOfSize:13]
                                                                                              }];
        NSRange termsRange = [base rangeOfString:terms];
        if (termsRange.location != NSNotFound) {
            [attr addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:13] range:termsRange];
        }
        
        NSRange privacyRange = [base rangeOfString:privacy];
        if (privacyRange.location != NSNotFound) {
            [attr addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:13] range:privacyRange];
        }

        label.attributedText = attr;

        
        UIGestureRecognizer *tap = [[UITapGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer *sender,
                                                                                        UIGestureRecognizerState state,
                                                                                        CGPoint location) {
            
            UITapGestureRecognizer *tapSender = (UITapGestureRecognizer *)sender;
            if ([tapSender didTapAttributedTextInLabel:label inRange:termsRange]) {
                NSURL *termsURL = [NSURL URLWithString:@"http://www.inaturalist.org/pages/terms"];
                [[UIApplication sharedApplication] openURL:termsURL];
            } else if ([tapSender didTapAttributedTextInLabel:label inRange:privacyRange]) {
                NSURL *privacyURL = [NSURL URLWithString:@"http://www.inaturalist.org/pages/privacy"];
                [[UIApplication sharedApplication] openURL:privacyURL];
            }
        }];
        label.userInteractionEnabled = YES;
        [label addGestureRecognizer:tap];
        
        label;
    });
    [self.view addSubview:self.termsLabel];
    
    NSDictionary *views = @{
                            @"bg": background,
                            @"tv": self.signupTableView,
                            @"top": self.topLayoutGuide,
                            @"terms": self.termsLabel,
                            };
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[bg]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[bg]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[terms]-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[tv]-|"
                                                                     options:0
                                                                     metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[top]-0-[tv]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[terms]-20-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];


}

#pragma mark - UITableView delegate/datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 5;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item < 3) {
        EditableTextFieldCell *cell = [tableView dequeueReusableCellWithIdentifier:@"EditableText"];
        
        [self configureEditableTextCell:cell forIndexPath:indexPath];
        
        return cell;
    } else if (indexPath.item == 3) {
        CheckboxCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Checkbox"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor clearColor];
        cell.tintColor = [UIColor whiteColor];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        });
        NSString *base = NSLocalizedString(@"Yes, license my content so scientists can use my data. Learn More", @"Base text for the license my content checkbox during account creation");
        NSString *emphasis = NSLocalizedString(@"Learn More", @"Emphasis text for the license my content checkbox. Must be a substring of the base string.");
        cell.checkText.attributedText = [NSAttributedString inat_attrStrWithBaseStr:base
                                                                          baseAttrs:@{
                                                                                      NSFontAttributeName: [UIFont systemFontOfSize:12.0f]
                                                                                      }
                                                                           emSubstr:emphasis
                                                                            emAttrs:@{
                                                                                      NSFontAttributeName: [UIFont boldSystemFontOfSize:12.0f]
                                                                                      }];
        NSRange emphasisRange = [base rangeOfString:emphasis];
        if (emphasisRange.location != NSNotFound) {
            cell.checkText.userInteractionEnabled = YES;
            UIGestureRecognizer *tap = [[UITapGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer *sender,
                                                                                            UIGestureRecognizerState state,
                                                                                            CGPoint location) {
                
                NSString *creativeCommons = NSLocalizedString(@"Check this box if you want to apply a Creative Commons Attribution-NonCommercial license to your photos. You can choose a different license or remove the license later, but this is the best license for sharing with researchers.", @"Alert text for the license content checkbox during create account.");

                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                                message:creativeCommons
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
                
            }];
            
            [cell.checkText addGestureRecognizer:tap];
        }

        return cell;
    } else {
        RoundedButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Button"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        [cell.roundedButton setTitle:NSLocalizedString(@"Sign up", @"text for sign up button on sign up screen")
                            forState:UIControlStateNormal];
        cell.roundedButton.tintColor = [UIColor whiteColor];
        cell.roundedButton.backgroundColor = [[UIColor inatTint] colorWithAlphaComponent:0.6f];
        cell.roundedButton.titleLabel.font = [UIFont boldSystemFontOfSize:18.0f];
        
        // TODO: extract shareData and submit it here?
        
        [cell.roundedButton bk_addEventHandler:^(id sender) {
            [self signupAction];
        } forControlEvents:UIControlEventTouchUpInside];
        
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == 3) {
        return 55.0f;
    } else {
        return 44.0f;
    }
}


- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == 3) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        if (cell.selected) {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
            // don't follow through with selection
            return nil;
        }
    }
    // follow through with selection
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == 3)
        shareData = YES;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == 3) {
        shareData = NO;
    }
}

- (void)configureEditableTextCell:(EditableTextFieldCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    cell.textField.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2f];
    cell.textField.tintColor = [UIColor whiteColor];
    cell.textField.textColor = [UIColor whiteColor];
    cell.backgroundColor = [UIColor clearColor];

    cell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    cell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    cell.textField.keyboardType = UIKeyboardTypeDefault;
    cell.textField.returnKeyType = UIReturnKeyNext;

    NSString *placeholderText;
    UIColor *placeholderTint = [[UIColor whiteColor] colorWithAlphaComponent:0.5f];
    NSDictionary *placeholderAttrs = @{
                                       NSForegroundColorAttributeName: placeholderTint,
                                       };

    if (indexPath.item == 0) {
        placeholderText = NSLocalizedString(@"Email", @"Placeholder text for the email text field in signup");
        
        cell.textField.keyboardType = UIKeyboardTypeEmailAddress;
        
        // icons for left view
        cell.activeLeftAttributedString = [FAKIonIcons iosEmailIconWithSize:30].attributedString;
        cell.inactiveLeftAttributedString = [FAKIonIcons iosEmailOutlineIconWithSize:30].attributedString;
        
        [cell.textField bk_addEventHandler:^(id sender) {
            // in case this cell scrolls off screen
            email = [cell.textField.text copy];
        } forControlEvents:UIControlEventEditingChanged];
        
        cell.textField.bk_shouldReturnBlock = ^(UITextField *tf) {
            // scroll to make password field visible
            NSIndexPath *nextIndexPath = [NSIndexPath indexPathForItem:indexPath.item +  1
                                                             inSection:indexPath.section];
            [self.signupTableView scrollToRowAtIndexPath:nextIndexPath
                                        atScrollPosition:UITableViewScrollPositionTop
                                                animated:YES];
            
            // switch keyboard focus to password field
            EditableTextFieldCell *nextCell = (EditableTextFieldCell *)[self.signupTableView cellForRowAtIndexPath:nextIndexPath];
            if (nextCell && [nextCell isKindOfClass:[EditableTextFieldCell class]]) {
                [nextCell.textField becomeFirstResponder];
            }
            
            // don't hide keyboard
            return NO;
        };

    } else if (indexPath.item == 1) {
        placeholderText = NSLocalizedString(@"Password", @"Placeholder text for the password text field in signup");

        cell.textField.secureTextEntry = YES;
        
        // icons for left view
        cell.activeLeftAttributedString = [FAKIonIcons iosLockedIconWithSize:30].attributedString;
        cell.inactiveLeftAttributedString = [FAKIonIcons iosLockedOutlineIconWithSize:30].attributedString;
        
        // right view
        cell.textField.rightViewMode = UITextFieldViewModeAlways;
        cell.textField.rightView = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, 44)];
            
            label.font = [UIFont systemFontOfSize:13.0f];
            label.textColor = [UIColor whiteColor];
            
            NSString *base = NSLocalizedString(@"Min. %d characters", @"Help text for password during create account.");
            label.text = [NSString stringWithFormat:base, INatMinPasswordLength];
            
            label;
        });
        [cell.textField bk_addEventHandler:^(id sender) {
            // in case this cell scrolls off the screen
            password = [cell.textField.text copy];
            
            // right view hides once minimum # of characters are entered
            if (cell.textField.text.length >= INatMinPasswordLength) {
                cell.textField.rightViewMode = UITextFieldViewModeNever;
            } else {
                cell.textField.rightViewMode = UITextFieldViewModeAlways;
            }
        } forControlEvents:UIControlEventEditingChanged];
        
        cell.textField.bk_shouldReturnBlock = ^(UITextField *tf) {
            // scroll to make username field visible
            NSIndexPath *nextIndexPath = [NSIndexPath indexPathForItem:indexPath.item +  1
                                                             inSection:indexPath.section];
            [self.signupTableView scrollToRowAtIndexPath:nextIndexPath
                                        atScrollPosition:UITableViewScrollPositionTop
                                                animated:YES];
            
            // switch keyboard focux to username field
            EditableTextFieldCell *nextCell = (EditableTextFieldCell *)[self.signupTableView cellForRowAtIndexPath:nextIndexPath];
            if (nextCell && [nextCell isKindOfClass:[EditableTextFieldCell class]]) {
                [nextCell.textField becomeFirstResponder];
            }
            
            // don't hide keyboard
            return NO;
        };

    } else {
        placeholderText = NSLocalizedString(@"Username", @"Placeholder text for the username text field in signup");

        // icons for left view
        cell.activeLeftAttributedString = [FAKIonIcons iosPersonIconWithSize:30].attributedString;
        cell.inactiveLeftAttributedString = [FAKIonIcons iosPersonOutlineIconWithSize:30].attributedString;
        
        [cell.textField bk_addEventHandler:^(id sender) {
            // in case this cell scrolls off the screen
            username = [cell.textField.text copy];
        } forControlEvents:UIControlEventEditingChanged];
        
        cell.textField.returnKeyType = UIReturnKeyGo;
        
        cell.textField.bk_shouldReturnBlock = ^(UITextField *tf) {
            [self signupAction];
            
            // hide the keyboard
            [tf resignFirstResponder];
            
            return NO;
        };

    }
    
    cell.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholderText
                                                                           attributes:placeholderAttrs];

}

- (void)signupAction {
    if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Internet connection required",nil)
                                    message:NSLocalizedString(@"Try again next time you're connected to the Internet.", nil)
                                   delegate:self
                          cancelButtonTitle:NSLocalizedString(@"OK",nil)
                          otherButtonTitles:nil] show];
        return;
    }
    
    // validators
    if (!email || ![email containsString:@"@"]) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Invalid Email Address",
                                                             "Error for bad email when making account.")];
        return;
    }
    if (!password || password.length < INatMinPasswordLength) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Passwords must be six characters in length.",
                                                             @"Error for bad password when making account")];
        return;
    }
    if (!username) {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Invalid Username",
                                                             @"Error for bad username hwne making account.")];
        return;
    }
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Creating iNaturalist account...", @"Notice while we're creating an iNat account for them")
                         maskType:SVProgressHUDMaskTypeGradient];

    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate.loginController createAccountWithEmail:email
                                               password:password
                                               username:username
                                                success:^(NSDictionary *info) {
                                                    [SVProgressHUD showSuccessWithStatus:nil];
                                                    if ([appDelegate.window.rootViewController isEqual:self.navigationController]) {
                                                        [appDelegate showMainUI];
                                                    } else {
                                                        [self dismissViewControllerAnimated:YES completion:nil];
                                                    }
                                                }
                                                failure:^(NSError *error) {
                                                    NSString *errMsg;
                                                    if (error) {
                                                        errMsg = error.localizedDescription;
                                                    } else {
                                                        errMsg = NSLocalizedString(@"Failed to create an iNat account. Please try again.",
                                                                                   @"Uknown iNaturalist create account error");
                                                    }
                                                    [SVProgressHUD showErrorWithStatus:errMsg];
                                                }];
}

@end
