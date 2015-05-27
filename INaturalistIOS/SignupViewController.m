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
#import <JDFTooltips/JDFTooltips.h>

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
    JDFTooltipView *tooltip;
    UITapGestureRecognizer *tapAway;
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
    
    //self.automaticallyAdjustsScrollViewInsets = YES;
    
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
    
    NSDictionary *views = @{
                            @"bg": background,
                            @"tv": self.signupTableView,
                            @"top": self.topLayoutGuide,
                            };
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[bg]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[bg]-0-|"
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
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        cell.textField.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2f];
        cell.textField.tintColor = [UIColor whiteColor];
        cell.textField.textColor = [UIColor whiteColor];
        cell.backgroundColor = [UIColor clearColor];
        
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
                
                if (tooltip && tooltip.superview)
                    return;
                
                UITapGestureRecognizer *tapSender = (UITapGestureRecognizer *)sender;
                if ([tapSender didTapAttributedTextInLabel:cell.checkText inRange:emphasisRange]) {
                    
                    NSString *tooltipText = NSLocalizedString(@"Check this box if you want to apply a Creative Commons Attribution-NonCommercial license to your photos. You can choose a different license or remove the license later, but this is the best license for sharing with researchers.", @"Tooltip text for the license content checkbox during create account.");
                    
                    tooltip = [[JDFTooltipView alloc] initWithTargetView:cell.checkIcon
                                                                hostView:self.view
                                                             tooltipText:tooltipText
                                                          arrowDirection:JDFTooltipViewArrowDirectionDown
                                                                   width:300.0f
                                                     showCompletionBlock:^{
                                                         if (!tapAway) {
                                                             tapAway = [[UITapGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
                                                                 [tooltip hideAnimated:YES];
                                                             }];
                                                             [self.view addGestureRecognizer:tapAway];
                                                         }
                                                         tapAway.enabled = YES;
                                                     } hideCompletionBlock:^{
                                                         tapAway.enabled = NO;
                                                     }];
                    tooltip.tooltipBackgroundColour = [UIColor whiteColor];
                    tooltip.textColour = [UIColor blackColor];
                    
                    [tooltip show];
                }
                
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
            if (!email || !password || !username) {
                [SVProgressHUD showErrorWithStatus:@"A Field is Missing"];
                return;
            }
            INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[UIApplication sharedApplication].delegate;
            [appDelegate.loginController createAccountWithEmail:email
                                                       password:password
                                                       username:username
                                                        success:^(NSDictionary *info) {
                                                            NSLog(@"success: %@", info);
                                                        }
                                                        failure:^(NSError *error) {
                                                            NSLog(@"failed: %@", error);
                                                        }];
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
    
    UIColor *placeholderTint = [[UIColor whiteColor] colorWithAlphaComponent:0.5f];
    NSDictionary *placeholderAttrs = @{
                                       NSForegroundColorAttributeName: placeholderTint,
                                       };

    if (indexPath.item == 0) {
        NSString *placeholderText = NSLocalizedString(@"Email", @"Placeholder text for the email text field in signup");
        cell.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholderText
                                                                               attributes:placeholderAttrs];
        
        cell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        cell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        cell.textField.keyboardType = UIKeyboardTypeEmailAddress;

        cell.textField.leftViewMode = UITextFieldViewModeAlways;
        
        FAKIcon *mailOutline = [FAKIonIcons iosEmailOutlineIconWithSize:30];
        FAKIcon *mailFilled = [FAKIonIcons iosEmailIconWithSize:30];
        
        cell.textField.leftView = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 44)];
            
            label.attributedText = mailOutline.attributedString;
            label.textColor = [UIColor whiteColor];
            label.textAlignment = NSTextAlignmentCenter;
            
            label;
        });
        
        [cell.textField bk_addEventHandler:^(id sender) {
            [((UILabel *)cell.textField.leftView) setAttributedText:mailFilled.attributedString];
        } forControlEvents:UIControlEventEditingDidBegin];
        
        [cell.textField bk_addEventHandler:^(id sender) {
            [((UILabel *)cell.textField.leftView) setAttributedText:mailOutline.attributedString];
        } forControlEvents:UIControlEventEditingDidEnd];
        
        [cell.textField bk_addEventHandler:^(id sender) {
            // in case this cell scrolls off screen
            email = [cell.textField.text copy];
        } forControlEvents:UIControlEventEditingChanged];


    } else if (indexPath.item == 1) {
        NSString *placeholderText = NSLocalizedString(@"Password", @"Placeholder text for the password text field in signup");
        cell.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholderText
                                                                               attributes:placeholderAttrs];

        cell.textField.secureTextEntry = YES;
        
        cell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        cell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        cell.textField.keyboardType = UIKeyboardTypeDefault;
        
        cell.textField.rightViewMode = UITextFieldViewModeAlways;
        cell.textField.rightView = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, 44)];
            
            label.font = [UIFont systemFontOfSize:13.0f];
            label.textColor = [UIColor whiteColor];

            label.text = NSLocalizedString(@"Min. 6 characters", @"Minimum six characters help text on signup");
            
            label;
        });
        
        cell.textField.leftViewMode = UITextFieldViewModeAlways;
        
        FAKIcon *lockedOutline = [FAKIonIcons iosLockedOutlineIconWithSize:30];
        FAKIcon *lockedFilled = [FAKIonIcons iosLockedIconWithSize:30];
        FAKIcon *unlockedOutline = [FAKIonIcons iosUnlockedOutlineIconWithSize:30];
        FAKIcon *unlockedFilled = [FAKIonIcons iosUnlockedIconWithSize:30];
        
        void(^configureLockIcon)(BOOL, BOOL) = ^(BOOL isTextEntrySecure, BOOL isEditing) {
            NSAttributedString *newIconAttrString;
            if (isEditing) {
                if (cell.textField.secureTextEntry) {
                    newIconAttrString = lockedFilled.attributedString;
                } else {
                    newIconAttrString = unlockedFilled.attributedString;
                }
            } else {
                if (cell.textField.secureTextEntry) {
                    newIconAttrString = lockedOutline.attributedString;
                } else {
                    newIconAttrString = unlockedOutline.attributedString;
                }
            }
            
            [UIView performWithoutAnimation:^{
                [((UIButton *)cell.textField.leftView) setAttributedTitle:newIconAttrString
                                                                 forState:UIControlStateNormal];
                [cell.textField.leftView layoutIfNeeded];
            }];
        };
        
        [cell.textField bk_addEventHandler:^(id sender) {
            configureLockIcon(cell.textField.secureTextEntry, YES);
        } forControlEvents:UIControlEventEditingDidBegin];
        
        [cell.textField bk_addEventHandler:^(id sender) {
            configureLockIcon(cell.textField.secureTextEntry, NO);
        } forControlEvents:UIControlEventEditingDidEnd];
        
        [cell.textField bk_addEventHandler:^(id sender) {
            if (cell.textField.text.length > 0) {
                cell.textField.rightViewMode = UITextFieldViewModeNever;
            } else {
                cell.textField.rightViewMode = UITextFieldViewModeAlways;
            }
            // just in case this cell scrolls off the screen
            password = [cell.textField.text copy];
        } forControlEvents:UIControlEventEditingChanged];
        
        cell.textField.leftView = ({
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            button.frame = CGRectMake(0, 0, 60, 44);
            
            button.tintColor = [UIColor whiteColor];
            
            [button bk_addEventHandler:^(id sender) {
                // toggle secure text entry
                cell.textField.secureTextEntry = !cell.textField.secureTextEntry;
                
                // fake a change to the text so that the caret position
                // updates. not sure why -setNeedsLayout shouldn't work here.
                NSString *text = cell.textField.text;
                cell.textField.text = [text stringByAppendingString:@" "];
                cell.textField.text = text;

                // update lock icon
                configureLockIcon(cell.textField.secureTextEntry, cell.textField.isFirstResponder);

            } forControlEvents:UIControlEventTouchUpInside];
            
            button;
        });
        configureLockIcon(cell.textField.secureTextEntry, NO);
        
    } else {
        NSString *placeholderText = NSLocalizedString(@"Username", @"Placeholder text for the username text field in signup");
        cell.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholderText
                                                                               attributes:placeholderAttrs];

        cell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        cell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        cell.textField.keyboardType = UIKeyboardTypeDefault;
        
        cell.textField.leftViewMode = UITextFieldViewModeAlways;
        
        FAKIcon *personOutline = [FAKIonIcons iosPersonOutlineIconWithSize:30];
        FAKIcon *personFilled = [FAKIonIcons iosPersonIconWithSize:30];

        cell.textField.leftView = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 44)];
            
            label.attributedText = personOutline.attributedString;
            label.textAlignment = NSTextAlignmentCenter;
            label.textColor = [UIColor whiteColor];
            
            label;
        });
        
        [cell.textField bk_addEventHandler:^(id sender) {
            [((UILabel *)cell.textField.leftView) setAttributedText:personFilled.attributedString];
        } forControlEvents:UIControlEventEditingDidBegin];
        
        [cell.textField bk_addEventHandler:^(id sender) {
            [((UILabel *)cell.textField.leftView) setAttributedText:personOutline.attributedString];
        } forControlEvents:UIControlEventEditingDidEnd];
        
        [cell.textField bk_addEventHandler:^(id sender) {
            // just in case this cell scrolls off the screen
            username = [cell.textField.text copy];
        } forControlEvents:UIControlEventEditingChanged];
    }
}

@end
