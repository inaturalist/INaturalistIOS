//
//  LoginViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/17/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <SVProgressHUD/SVProgressHUD.h>
#import <FacebookSDK/FacebookSDK.h>
#import <FontAwesomeKit/FAKIonicons.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <NXOAuth2Client/NXOAuth2.h>

#import "LoginViewController.h"
#import "LoginController.h"
#import "Analytics.h"
#import "INaturalistAppDelegate.h"
#import "SplitTextButton.h"
#import "EditableTextFieldCell.h"
#import "RoundedButtonCell.h"
#import "UIColor+INAturalist.h"
#import "INatWebController.h"


@interface LoginViewController () <UITableViewDataSource, UITableViewDelegate, INatWebControllerDelegate> {
    NSString *username, *password;
}
@end

@implementation LoginViewController

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Log In", @"title of the log in screen");
    
    if (self.cancellable) {
        UIImage *closeImage = ({
            FAKIcon *close = [FAKIonIcons iosCloseEmptyIconWithSize:40];
            [close addAttribute:NSForegroundColorAttributeName
                          value:[UIColor whiteColor]];
            [close imageWithSize:CGSizeMake(40, 40)];
        });
        __weak typeof(self)weakSelf = self;
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] bk_initWithImage:closeImage
                                                                                     style:UIBarButtonItemStylePlain
                                                                                   handler:^(id sender) {
                                                                                       __strong typeof(weakSelf)strongSelf = weakSelf;
                                                                                       [strongSelf dismissViewControllerAnimated:YES
                                                                                                                      completion:nil];
                                                                                   }];
        self.navigationItem.rightBarButtonItem.tintColor = [UIColor whiteColor];
    }
    
    UIImageView *background = ({
        UIImageView *iv = [[UIImageView alloc] initWithFrame:self.view.bounds];
        iv.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        
        iv.image = self.backgroundImage ?: [UIImage imageNamed:@"SignUp_OrangeFlower.jpg"];

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
    
    self.loginTableView = ({
        UITableView *tv = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        tv.translatesAutoresizingMaskIntoConstraints = NO;
        
        tv.dataSource = self;
        tv.delegate = self;
        
        tv.scrollEnabled = NO;
        
        tv.backgroundColor = [UIColor clearColor];
        tv.separatorColor = [UIColor clearColor];
        
        [tv registerClass:[EditableTextFieldCell class] forCellReuseIdentifier:@"TextField"];
        [tv registerClass:[RoundedButtonCell class] forCellReuseIdentifier:@"Button"];

        tv;
    });
    [self.view addSubview:self.loginTableView];
    
    self.orLabel = ({
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        
        label.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5f];
        label.text = NSLocalizedString(@"Or Log In with:", @"label above alternate login option buttons (ie g+, facebook)");
        label.textAlignment = NSTextAlignmentCenter;
        
        label;
    });
    [self.view addSubview:self.orLabel];
    
    UIView *socialContainer = ({
        UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        
        view;
    });
    [self.view addSubview:socialContainer];
    
    self.gButton = ({
        SplitTextButton *button = [[SplitTextButton alloc] initWithFrame:CGRectZero];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSString *google = NSLocalizedString(@"Google", @"Name of Google for the G+ signin button");
        NSDictionary *attrs = @{
                                NSFontAttributeName: [UIFont boldSystemFontOfSize:16.0f],
                                };
        
        button.trailingTitleLabel.textAlignment = NSTextAlignmentCenter;
        button.trailingTitleLabel.attributedText = [[NSAttributedString alloc] initWithString:google
                                                                                attributes:attrs];

        button.leadingTitleLabel.attributedText = [FAKIonIcons socialGoogleplusIconWithSize:25.0f].attributedString;
        
        
        [button bk_addEventHandler:^(id sender) {
            if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Internet connection required",nil)
                                            message:NSLocalizedString(@"Try again next time you're connected to the Internet.", nil)
                                           delegate:nil
                                  cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                  otherButtonTitles:nil] show];
                return;
            }
            
            INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
            __weak typeof(self)weakSelf = self;
            [appDelegate.loginController loginWithGoogleUsingNavController:self.navigationController
                                                                   success:^(NSDictionary *info) {
                                                                       __strong typeof(weakSelf)strongSelf = weakSelf;
                                                                       if ([appDelegate.window.rootViewController isEqual:strongSelf.navigationController]) {
                                                                           [appDelegate showMainUI];
                                                                       } else {
                                                                           [strongSelf dismissViewControllerAnimated:YES completion:nil];
                                                                       }
                                                                       if (strongSelf.selectedPartner) {
                                                                           [appDelegate.loginController loggedInUserSelectedPartner:strongSelf.selectedPartner
                                                                                                                         completion:nil];
                                                                       }
                                                                   } failure:^(NSError *error) {
                                                                       NSString *alertTitle = NSLocalizedString(@"Oops", @"Title error with oops text.");
                                                                       NSString *alertMsg;
                                                                       if (error) {
                                                                           alertMsg = error.localizedDescription;
                                                                       } else {
                                                                           alertMsg = NSLocalizedString(@"Failed to login to Google Plus. Please try again later.",
                                                                                                        @"Unknown google login error");
                                                                       }
                                                                       [[[UIAlertView alloc] initWithTitle:alertTitle
                                                                                                   message:alertMsg
                                                                                                  delegate:nil
                                                                                         cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                                                         otherButtonTitles:nil] show];
                                                                   }];
        
        } forControlEvents:UIControlEventTouchUpInside];

        button;
    });
    [socialContainer addSubview:self.gButton];
    
    self.faceButton = ({
        SplitTextButton *button = [[SplitTextButton alloc] initWithFrame:CGRectZero];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSString *face = NSLocalizedString(@"Facebook", @"Name of Facebook for the Facebook signin button");
        NSDictionary *attrs = @{
                                NSFontAttributeName: [UIFont boldSystemFontOfSize:15.0f],
                                };
        
        button.trailingTitleLabel.textAlignment = NSTextAlignmentCenter;
        button.trailingTitleLabel.attributedText = [[NSAttributedString alloc] initWithString:face
                                                                                attributes:attrs];

        button.leadingTitleLabel.attributedText = [FAKIonIcons socialFacebookIconWithSize:25.0f].attributedString;

        [button bk_addEventHandler:^(id sender) {
            if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Internet connection required",nil)
                                            message:NSLocalizedString(@"Try again next time you're connected to the Internet.", nil)
                                           delegate:nil
                                  cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                  otherButtonTitles:nil] show];
                return;
            }
            
            INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
            __weak typeof(self)weakSelf = self;
            [appDelegate.loginController loginWithFacebookSuccess:^(NSDictionary *info) {
                __strong typeof(weakSelf)strongSelf = weakSelf;
                if ([appDelegate.window.rootViewController isEqual:strongSelf.navigationController]) {
                    [appDelegate showMainUI];
                } else {
                    [strongSelf dismissViewControllerAnimated:YES completion:nil];
                }
                if (strongSelf.selectedPartner) {
                    [appDelegate.loginController loggedInUserSelectedPartner:strongSelf.selectedPartner
                                                                  completion:nil];
                }
            } failure:^(NSError *error) {
                NSString *alertTitle = NSLocalizedString(@"Oops", @"Title error with oops text.");
                NSString *alertMsg;
                if (error) {
                    alertMsg = error.localizedDescription;
                } else {
                    alertMsg = NSLocalizedString(@"Failed to login to Facebook. Please try again later.",
                                            @"Unknown facebook login error");
                }
                [[[UIAlertView alloc] initWithTitle:alertTitle
                                           message:alertMsg
                                          delegate:nil
                                 cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil] show];
            }];
        } forControlEvents:UIControlEventTouchUpInside];
        
        button;

    });
    [socialContainer addSubview:self.faceButton];
    
    UIView *spacer = [UIView new];
    UIView *spacer2 = [UIView new];
    
    __weak typeof(self)weakSelf = self;
    [@[spacer, spacer2] bk_each:^(UIView *view) {
        __strong typeof(weakSelf)strongSelf = weakSelf;
        view.frame = CGRectZero;
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [strongSelf.view addSubview:view];
    }];
    
    NSDictionary *views = @{
                            @"tv": self.loginTableView,
                            @"spacer": spacer,
                            @"spacer2": spacer2,
                            @"or": self.orLabel,
                            @"g": self.gButton,
                            @"face": self.faceButton,
                            @"top": self.topLayoutGuide,
                            @"social": socialContainer,
                            };
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.loginTableView
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.loginTableView
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:nil
                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                         multiplier:1.0f
                                                           constant:290.0f]];

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[or]-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:socialContainer
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:socialContainer
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:nil
                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                         multiplier:1.0f
                                                           constant:290.0f]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[g]-[face(==g)]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[g]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[face]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[top]-20-[tv(==152)]"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[or]-20-[social(==44)]-100-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];



}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO];

    // setup custom navigation bar style
    // white button tint
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    [self.navigationController.navigationBar setTitleTextAttributes:@{
                                                                      NSForegroundColorAttributeName:
                                                                          [UIColor whiteColor]
                                                                      }];
    
    // completely clear navbar background
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    [self.navigationController.navigationBar setShadowImage:[UIImage new]];
    [self.navigationController.navigationBar setTranslucent:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[Analytics sharedClient] timedEvent:kAnalyticsEventNavigateLogin];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[Analytics sharedClient] endTimedEvent:kAnalyticsEventNavigateLogin];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    // if the VC catches a tap, it means nobody else did
    // resign first responder from the textfield subviews
    [self.view endEditing:YES];
}

#pragma mark TableView datasource/delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0)
        return 2;
    else
        return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 1)
        return 20.0f;
    else
        return 0.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [UIView new];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        EditableTextFieldCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TextField"];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [self configureEditableTextCell:cell forIndexPath:indexPath];
        
        return cell;
    } else {
        RoundedButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Button"];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.roundedButton.tintColor = [UIColor whiteColor];
        cell.roundedButton.backgroundColor = [[UIColor inatTint] colorWithAlphaComponent:0.6f];
        cell.roundedButton.titleLabel.font = [UIFont boldSystemFontOfSize:18.0f];
        
        [cell.roundedButton setTitle:NSLocalizedString(@"Log in", @"Title for login button")
                            forState:UIControlStateNormal];
        
        __weak typeof(self)weakSelf = self;
        [cell.roundedButton bk_addEventHandler:^(id sender) {
            [weakSelf loginAction];
        } forControlEvents:UIControlEventTouchUpInside];
        
        cell.roundedButton.enabled = NO;
        cell.roundedButton.alpha = 0.5f;
        
        return cell;
    }
}

#pragma mark - Editable Text Cell config helper

- (void)configureEditableTextCell:(EditableTextFieldCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    
    cell.backgroundColor = [UIColor clearColor];
    
    cell.textField.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2f];
    cell.textField.tintColor = [UIColor whiteColor];
    cell.textField.textColor = [UIColor whiteColor];
    
    cell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    cell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    cell.textField.keyboardType = UIKeyboardTypeDefault;
    
    NSString *placeholderText;
    UIColor *placeholderTint = [[UIColor whiteColor] colorWithAlphaComponent:0.5f];
    NSDictionary *placeholderAttrs = @{
                                       NSForegroundColorAttributeName: placeholderTint,
                                       };
    
    if (indexPath.item == 0) {
        placeholderText = NSLocalizedString(@"Username", @"Placeholder text for the username text field in signup");
        
        cell.textField.rightViewMode = UITextFieldViewModeAlways;
        cell.textField.rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 15.0, cell.textField.frame.size.height)];
        // left icons
        cell.activeLeftAttributedString = [FAKIonIcons iosPersonIconWithSize:30].attributedString;
        cell.inactiveLeftAttributedString = [FAKIonIcons iosPersonOutlineIconWithSize:30].attributedString;
        
        __weak typeof(self)weakSelf = self;
        [cell.textField bk_addEventHandler:^(id sender) {
            // just in case this cell scrolls off the screen
            username = [cell.textField.text copy];
            [weakSelf validateLoginButton];
        } forControlEvents:UIControlEventEditingChanged];
        
        cell.textField.bk_shouldReturnBlock = ^(UITextField *tf) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            
            // scroll to make password field visible
            NSIndexPath *nextIndexPath = [NSIndexPath indexPathForItem:indexPath.item +  1
                                                             inSection:indexPath.section];
            [strongSelf.loginTableView scrollToRowAtIndexPath:nextIndexPath
                                             atScrollPosition:UITableViewScrollPositionTop
                                                     animated:YES];
            
            // switch keyboard focus to username field
            EditableTextFieldCell *nextCell = (EditableTextFieldCell *)[strongSelf.loginTableView cellForRowAtIndexPath:nextIndexPath];
            if (nextCell && [nextCell isKindOfClass:[EditableTextFieldCell class]]) {
                [nextCell.textField becomeFirstResponder];
            }

            // don't hide the keyboard
            return NO;
        };
        
    } else {
        placeholderText = NSLocalizedString(@"Password", @"Placeholder text for the password text field in signup");
        
        cell.textField.secureTextEntry = YES;
        
        // left icons
        cell.activeLeftAttributedString = [FAKIonIcons iosLockedIconWithSize:30].attributedString;
        cell.inactiveLeftAttributedString = [FAKIonIcons iosLockedOutlineIconWithSize:30].attributedString;

        // right view
        cell.textField.rightViewMode = UITextFieldViewModeAlways;
        cell.textField.rightView = ({
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            button.frame = CGRectMake(0, 0, 65, 44);
            
            button.titleLabel.font = [UIFont systemFontOfSize:12.0f];
            button.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5f];
            
            [button setTitle:NSLocalizedString(@"Forgot?", @"Title for forgot password button.")
                    forState:UIControlStateNormal];
            
            __weak typeof(self)weakSelf = self;
            [button bk_addEventHandler:^(id sender) {
                __strong typeof(weakSelf)strongSelf = weakSelf;
                if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
                    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Internet connection required",nil)
                                                message:NSLocalizedString(@"Try again next time you're connected to the Internet.", nil)
                                               delegate:nil
                                      cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                      otherButtonTitles:nil] show];
                    return;
                }

                INatWebController *webController = [[INatWebController alloc] init];
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/forgot_password.mobile", INatWebBaseURL]];
                [webController setUrl:url];
                webController.delegate = strongSelf;
                [strongSelf.navigationController pushViewController:webController animated:YES];

            } forControlEvents:UIControlEventTouchUpInside];
            
            button;
        });
        
        __weak typeof(self)weakSelf = self;
        [cell.textField bk_addEventHandler:^(id sender) {
            // just in case this cell scrolls off the screen
            password = [cell.textField.text copy];
            [weakSelf validateLoginButton];
        } forControlEvents:UIControlEventEditingChanged];
        
        cell.textField.bk_shouldReturnBlock = ^(UITextField *tf) {
            [weakSelf loginAction];
            
            // hide keyboard
            [tf resignFirstResponder];

            return NO;
        };

    }
    
    cell.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholderText
                                                                           attributes:placeholderAttrs];

}

#pragma mark - Login helper

- (void)loginAction {
    if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Internet connection required",nil)
                                    message:NSLocalizedString(@"Try again next time you're connected to the Internet.", nil)
                                   delegate:self
                          cancelButtonTitle:NSLocalizedString(@"OK",nil)
                          otherButtonTitles:nil] show];
        return;
    }
    
    // validators
    BOOL isValid = YES;
    NSString *alertMsg;
    if (!username) {
        isValid = NO;
        alertMsg = NSLocalizedString(@"Invalid Username",
                                     @"Error for bad username hwne making account.");
    }
    if (!password || password.length < INatMinPasswordLength) {
        isValid = NO;
        alertMsg = NSLocalizedString(@"Passwords must be six characters in length.",
                                     @"Error for bad password when making account");
    }
    if (!isValid) {
        NSString *alertTitle = NSLocalizedString(@"Oops", @"Title error with oops text.");
        if (!alertMsg) alertMsg = NSLocalizedString(@"Invalid input", @"Unknown invalid input");

        [[[UIAlertView alloc] initWithTitle:alertTitle
                                    message:alertMsg
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil] show];
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [SVProgressHUD showWithStatus:NSLocalizedString(@"Logging in...", @"Notice while we're logging them in")
                             maskType:SVProgressHUDMaskTypeGradient];
    });
    
    __weak typeof(self)weakSelf = self;
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[UIApplication sharedApplication].delegate;
    [appDelegate.loginController loginWithUsername:username
                                          password:password
                                           success:^(NSDictionary *info) {
                                               __strong typeof(weakSelf)strongSelf = weakSelf;
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   [SVProgressHUD showSuccessWithStatus:nil];
                                               });
                                               if (strongSelf.selectedPartner) {
                                                   [appDelegate.loginController loggedInUserSelectedPartner:strongSelf.selectedPartner
                                                                                                 completion:nil];
                                               }
                                               if ([appDelegate.window.rootViewController isEqual:strongSelf.navigationController]) {
                                                   [appDelegate showMainUI];
                                               } else {
                                                   [strongSelf dismissViewControllerAnimated:YES completion:nil];
                                               }
                                           } failure:^(NSError *error) {
                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                   [SVProgressHUD dismiss];
                                               });

                                               NSString *alertTitle = NSLocalizedString(@"Oops", @"Title error with oops text.");
                                               NSString *alertMsg;
                                               if (error) {
                                                   if ([error.domain isEqualToString:NXOAuth2HTTPErrorDomain] && error.code == 401) {
                                                       alertMsg = NSLocalizedString(@"Incorrect username or password.",
                                                                                    @"Error msg when we get a 401 from the server");
                                                   } else {
                                                       alertMsg = error.localizedDescription;
                                                   }
                                               } else {
                                                   alertMsg = NSLocalizedString(@"Failed to login to iNaturalist. Please try again.",
                                                                                @"Unknown iNat login error");
                                               }
                                               [[[UIAlertView alloc] initWithTitle:alertTitle
                                                                           message:alertMsg
                                                                          delegate:nil
                                                                 cancelButtonTitle:NSLocalizedString(@"OK", nil)
                                                                 otherButtonTitles:nil] show];
                                           }];
}

- (void)validateLoginButton {
    NSIndexPath *buttonIndexPath = [NSIndexPath indexPathForItem:0 inSection:1];
    RoundedButtonCell *buttonCell = (RoundedButtonCell *)[self.loginTableView cellForRowAtIndexPath:buttonIndexPath];
    
    if (buttonCell && [buttonCell isKindOfClass:[RoundedButtonCell class]]) {
        if (password.length > 2 && username.length > 2) {
            buttonCell.roundedButton.enabled = YES;
            buttonCell.roundedButton.alpha = 1.0f;
        } else {
            buttonCell.roundedButton.enabled = NO;
            buttonCell.roundedButton.alpha = 0.5f;
        }
    }
}

#pragma mark - INatWebViewController delegate

- (BOOL)webView:(UIWebView *)webView shouldLoadRequest:(NSURLRequest *)request {
    if ([request.URL.path hasPrefix:@"/forgot_password"]) {
        return YES;
    }
    [self.navigationController popViewControllerAnimated:YES];
    
    // webviews may trigger their delegate methods more than once
    static UIAlertView *av;
    if (av) {
        [av dismissWithClickedButtonIndex:0 animated:YES];
        av = nil;
    }
    
    NSString *alertTitle = NSLocalizedString(@"Check your email",
                                             @"title of alert after you reset your password");
    NSString *alertMsg = NSLocalizedString(@"If the email address you entered is associated with an iNaturalist account, you should receive an email at that address with a link to reset your password.",
                                           @"body of alert after you reset your password");
    
    av = [[UIAlertView alloc] initWithTitle:alertTitle
                                    message:alertMsg
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil];
    [av show];
    
    return YES;
}

@end
