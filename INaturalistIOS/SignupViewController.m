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

@interface SignupViewController () <UITableViewDataSource, UITableViewDelegate> {
    UITableView *signupTableView;
    
    NSString *email, *password, *username;
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
    
    // inat green button tint
    [self.navigationController.navigationBar setTintColor:[UIColor inatTint]];
    
    // standard navigation bar
    [self.navigationController.navigationBar setBackgroundImage:nil
                                                  forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:nil];
    [self.navigationController.navigationBar setTranslucent:YES];
    [self.navigationController setNavigationBarHidden:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    EditableTextFieldCell *cell = (EditableTextFieldCell *)[signupTableView cellForRowAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    [cell.textField becomeFirstResponder];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.automaticallyAdjustsScrollViewInsets = YES;
    
    signupTableView = ({
        UITableView *tv = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        tv.translatesAutoresizingMaskIntoConstraints = NO;
        
        tv.backgroundColor = [UIColor whiteColor];
        tv.separatorColor = [UIColor clearColor];
        
        tv.dataSource = self;
        tv.delegate = self;
        [tv registerClass:[EditableTextFieldCell class] forCellReuseIdentifier:@"EditableText"];
        [tv registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Signup"];
        
        tv;
    });
    [self.view addSubview:signupTableView];
    
    NSDictionary *views = @{
                            @"tv": signupTableView,
                            };
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[tv]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[tv]-0-|"
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
        
        [self configureEditableTextCell:cell forIndexPath:indexPath];
        
        return cell;
    } else if (indexPath.item == 3) {
        // TBD: checkmark
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Signup"];
        cell.textLabel.text = @"checkbox TBD";
        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Signup"];
        
        [cell.contentView addSubview:({
            UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(15, 0, cell.bounds.size.width - 30, cell.bounds.size.height)];
            button.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
            
            button.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.4];
            button.tintColor = [UIColor whiteColor];
            
            [button setTitle:NSLocalizedString(@"SIGN UP", @"text for sign up button on sign up screen")
                    forState:UIControlStateNormal];
            button.titleLabel.font = [UIFont systemFontOfSize:32.0f];
            button.layer.cornerRadius = 2.0f;
            
            [button bk_addEventHandler:^(id sender) {
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
            
            button;
        })];
        
        return cell;
    }
}

- (void)configureEditableTextCell:(EditableTextFieldCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item == 0) {
        cell.textField.placeholder = NSLocalizedString(@"Email", @"Placeholder text for the email text field in signup");
        
        cell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        cell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        cell.textField.keyboardType = UIKeyboardTypeEmailAddress;

        cell.textField.leftViewMode = UITextFieldViewModeAlways;
        
        FAKIcon *mailOutline = [FAKIonIcons iosEmailOutlineIconWithSize:30];
        FAKIcon *mailFilled = [FAKIonIcons iosEmailIconWithSize:30];
        
        cell.textField.leftView = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 44)];
            
            label.attributedText = mailOutline.attributedString;
            label.textAlignment = NSTextAlignmentCenter;
            
            label;
        });
        
        [cell.textField bk_addEventHandler:^(id sender) {
            [((UILabel *)cell.textField.leftView) setAttributedText:mailFilled.attributedString];
        } forControlEvents:UIControlEventEditingDidBegin];
        
        [cell.textField bk_addEventHandler:^(id sender) {
            [((UILabel *)cell.textField.leftView) setAttributedText:mailOutline.attributedString];
            // just in case this scrolls off the screen
            email = [cell.textField.text copy];
        } forControlEvents:UIControlEventEditingDidEnd];


    } else if (indexPath.item == 1) {
        cell.textField.placeholder = NSLocalizedString(@"Password", @"Placeholder text for the password text field in signup");
        cell.textField.secureTextEntry = YES;
        
        cell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        cell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        cell.textField.keyboardType = UIKeyboardTypeDefault;
        
        cell.textField.rightViewMode = UITextFieldViewModeAlways;
        cell.textField.rightView = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 120, 44)];
            
            label.font = [UIFont systemFontOfSize:13.0f];
            label.tintColor = [UIColor grayColor];
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
            // just in case this scrolls off the screen
            password = [cell.textField.text copy];
        } forControlEvents:UIControlEventEditingDidEnd];
        
        [cell.textField bk_addEventHandler:^(id sender) {
            if (cell.textField.text.length > 0) {
                cell.textField.rightViewMode = UITextFieldViewModeNever;
            } else {
                cell.textField.rightViewMode = UITextFieldViewModeAlways;
            }
        } forControlEvents:UIControlEventEditingChanged];
        
        cell.textField.leftView = ({
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            button.frame = CGRectMake(0, 0, 60, 44);
            
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
        cell.textField.placeholder = NSLocalizedString(@"Username", @"Placeholder text for the username text field in signup");
        
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
            
            label;
        });
        
        [cell.textField bk_addEventHandler:^(id sender) {
            [((UILabel *)cell.textField.leftView) setAttributedText:personFilled.attributedString];
        } forControlEvents:UIControlEventEditingDidBegin];
        
        [cell.textField bk_addEventHandler:^(id sender) {
            [((UILabel *)cell.textField.leftView) setAttributedText:personOutline.attributedString];
            // just in case this scrolls off the screen
            username = [cell.textField.text copy];
        } forControlEvents:UIControlEventEditingDidEnd];

    }
}

@end
