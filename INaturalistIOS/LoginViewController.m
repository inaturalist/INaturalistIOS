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

#import "LoginViewController.h"
#import "LoginController.h"
#import "Analytics.h"
#import "INaturalistAppDelegate.h"
#import "SplitTextButton.h"
#import "EditableTextFieldCell.h"
#import "RoundedButtonCell.h"
#import "UIColor+INAturalist.h"
#import "INatWebController.h"
#import "GPPSignIn.h"
#import "GooglePlusAuthViewController.h"


@interface LoginViewController () <UITableViewDataSource, UITableViewDelegate, INatWebControllerDelegate> {
    NSString *username, *password;
    UITableView *loginTableView;
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
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] bk_initWithImage:closeImage
                                                                                     style:UIBarButtonItemStylePlain
                                                                                   handler:^(id sender) {
                                                                                       [self dismissViewControllerAnimated:YES
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
    
    loginTableView = ({
        UITableView *tv = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        tv.translatesAutoresizingMaskIntoConstraints = NO;
        
        tv.dataSource = self;
        tv.delegate = self;
        
        tv.backgroundColor = [UIColor clearColor];
        tv.separatorColor = [UIColor clearColor];
        
        [tv registerClass:[EditableTextFieldCell class] forCellReuseIdentifier:@"TextField"];
        [tv registerClass:[RoundedButtonCell class] forCellReuseIdentifier:@"Button"];

        tv;
    });
    [self.view addSubview:loginTableView];
    
    UILabel *orLabel = ({
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.translatesAutoresizingMaskIntoConstraints = NO;
        
        label.textColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5f];
        label.text = NSLocalizedString(@"Or login with:", @"label above alternate login option buttons (ie g+, facebook)");
        label.textAlignment = NSTextAlignmentCenter;
        
        label;
    });
    [self.view addSubview:orLabel];
    
    SplitTextButton *gButton = ({
        SplitTextButton *button = [[SplitTextButton alloc] initWithFrame:CGRectZero];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSString *google = NSLocalizedString(@"Google", @"Name of Google for the G+ signin button");
        NSDictionary *attrs = @{
                                NSFontAttributeName: [UIFont boldSystemFontOfSize:18.0f],
                                };
        
        button.rightTitleLabel.attributedText = [[NSAttributedString alloc] initWithString:google
                                                                                attributes:attrs];
        button.leftTitleLabel.attributedText = [FAKIonIcons socialGoogleplusIconWithSize:25.0f].attributedString;
        
        [button bk_addEventHandler:^(id sender) {
            if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Internet connection required",nil)
                                            message:NSLocalizedString(@"Try again next time you're connected to the Internet.", nil)
                                           delegate:self
                                  cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                  otherButtonTitles:nil] show];
                return;
            }
            
            INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
            
            GooglePlusAuthViewController *vc = [GooglePlusAuthViewController controllerWithScope:appDelegate.loginController.scopesForGoogleSignin
                                                                                        clientID:appDelegate.loginController.clientIdForGoogleSignin
                                                                                    clientSecret:nil
                                                                                keychainItemName:nil
                                                                                        delegate:appDelegate.loginController
                                                                                finishedSelector:@selector(viewController:finishedAuth:error:)];
            [self.navigationController pushViewController:vc animated:YES];
            
            // inat green button tint
            [self.navigationController.navigationBar setTintColor:[UIColor inatTint]];
            
            // standard navigation bar
            [self.navigationController.navigationBar setBackgroundImage:nil
                                                          forBarMetrics:UIBarMetricsDefault];
            [self.navigationController.navigationBar setShadowImage:nil];
            [self.navigationController.navigationBar setTranslucent:YES];
            [self.navigationController setNavigationBarHidden:NO];
        
        } forControlEvents:UIControlEventTouchUpInside];

        button;
    });
    [self.view addSubview:gButton];
    
    SplitTextButton *faceButton = ({
        SplitTextButton *button = [[SplitTextButton alloc] initWithFrame:CGRectZero];
        button.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSString *face = NSLocalizedString(@"Facebook", @"Name of Facebook for the Facebook signin button");
        NSDictionary *attrs = @{
                                NSFontAttributeName: [UIFont boldSystemFontOfSize:15.0f],
                                };
        
        button.rightTitleLabel.attributedText = [[NSAttributedString alloc] initWithString:face
                                                                                attributes:attrs];
        button.leftTitleLabel.attributedText = [FAKIonIcons socialFacebookIconWithSize:25.0f].attributedString;

        [button bk_addEventHandler:^(id sender) {
            if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Internet connection required",nil)
                                            message:NSLocalizedString(@"Try again next time you're connected to the Internet.", nil)
                                           delegate:self
                                  cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                  otherButtonTitles:nil] show];
                return;
            }
            
            INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
            [appDelegate.loginController loginWithFacebookSuccess:^(NSDictionary *info) {
                [self dismissViewControllerAnimated:YES completion:nil];
            } failure:^(NSError *error) {
                [SVProgressHUD showErrorWithStatus:error.localizedDescription];
            }];
        } forControlEvents:UIControlEventTouchUpInside];
        
        button;

    });
    [self.view addSubview:faceButton];
    
    UIView *spacer = [UIView new];
    UIView *spacer2 = [UIView new];
    
    [@[spacer, spacer2] bk_each:^(UIView *view) {
        view.frame = CGRectZero;
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:view];
    }];
    
    NSDictionary *views = @{
                            @"tv": loginTableView,
                            @"spacer": spacer,
                            @"spacer2": spacer2,
                            @"or": orLabel,
                            @"g": gButton,
                            @"face": faceButton,
                            @"top": self.topLayoutGuide,
                            };
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[tv]-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[or]-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[g]-[face]-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[top]-0-[tv]-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[or]-20-[g(==44)]-100-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[or]-20-[face(==44)]-100-|"
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
    return 20.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [UIView new];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        EditableTextFieldCell *cell = [tableView dequeueReusableCellWithIdentifier:@"TextField"];
        
        cell.textField.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.2f];
        cell.textField.tintColor = [UIColor whiteColor];
        cell.textField.textColor = [UIColor whiteColor];
        cell.backgroundColor = [UIColor clearColor];

        [self configureEditableTextCell:cell forIndexPath:indexPath];
        
        return cell;
    } else {
        RoundedButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Button"];
        
        cell.roundedButton.tintColor = [UIColor whiteColor];
        cell.roundedButton.backgroundColor = [[UIColor inatTint] colorWithAlphaComponent:0.6f];
        cell.roundedButton.titleLabel.font = [UIFont boldSystemFontOfSize:18.0f];
        
        [cell.roundedButton setTitle:NSLocalizedString(@"Log in", @"Title for login button")
                            forState:UIControlStateNormal];
        
        [cell.roundedButton bk_addEventHandler:^(id sender) {
            
            if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
                [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Internet connection required",nil)
                                            message:NSLocalizedString(@"Try again next time you're connected to the Internet.", nil)
                                           delegate:self
                                  cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                  otherButtonTitles:nil] show];
                return;
            }

            if (!username || !password) {
                [SVProgressHUD showErrorWithStatus:@"A Field is Missing"];
                return;
            }
            INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[UIApplication sharedApplication].delegate;
            [appDelegate.loginController loginWithUsername:username
                                                  password:password
                                                   success:^(NSDictionary *info) {
                                                       NSLog(@"success: %@", info);
                                                   } failure:^(NSError *error) {
                                                       NSLog(@"error: %@", error);
                                                   }];
        } forControlEvents:UIControlEventTouchUpInside];
        
        return cell;
        
        return cell;
    }
}


- (void)configureEditableTextCell:(EditableTextFieldCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    
    UIColor *placeholderTint = [[UIColor whiteColor] colorWithAlphaComponent:0.5f];
    NSDictionary *placeholderAttrs = @{
                                       NSForegroundColorAttributeName: placeholderTint,
                                       };
    
    if (indexPath.item == 0) {
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
    } else {

        NSString *placeholderText = NSLocalizedString(@"Password", @"Placeholder text for the password text field in signup");
        cell.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholderText
                                                                               attributes:placeholderAttrs];
        
        cell.textField.secureTextEntry = YES;
        
        cell.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        cell.textField.autocorrectionType = UITextAutocorrectionTypeNo;
        cell.textField.keyboardType = UIKeyboardTypeDefault;
        
        cell.textField.rightViewMode = UITextFieldViewModeAlways;
        cell.textField.rightView = ({
            UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
            button.frame = CGRectMake(0, 0, 80, 44);
            
            button.titleLabel.font = [UIFont systemFontOfSize:12.0f];
            button.tintColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5f];
            
            [button setTitle:NSLocalizedString(@"Forgot?", @"Title for forgot password button.")
                    forState:UIControlStateNormal];
            
            [button bk_addEventHandler:^(id sender) {
                
                if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
                    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Internet connection required",nil)
                                                message:NSLocalizedString(@"Try again next time you're connected to the Internet.", nil)
                                               delegate:self
                                      cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                      otherButtonTitles:nil] show];
                    return;
                }

                INatWebController *webController = [[INatWebController alloc] init];
                NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/forgot_password.mobile", INatWebBaseURL]];
                [webController setUrl:url];
                webController.delegate = self;
                [self.navigationController pushViewController:webController animated:YES];

            } forControlEvents:UIControlEventTouchUpInside];
            
            button;
        });
        
        cell.textField.leftViewMode = UITextFieldViewModeAlways;
        
        FAKIcon *lockedOutline = [FAKIonIcons iosLockedOutlineIconWithSize:30];
        FAKIcon *lockedFilled = [FAKIonIcons iosLockedIconWithSize:30];
        
        [cell.textField bk_addEventHandler:^(id sender) {
            [((UILabel *)cell.textField.leftView) setAttributedText:lockedFilled.attributedString];
        } forControlEvents:UIControlEventEditingDidBegin];
        
        [cell.textField bk_addEventHandler:^(id sender) {
            [((UILabel *)cell.textField.leftView) setAttributedText:lockedOutline.attributedString];
        } forControlEvents:UIControlEventEditingDidEnd];
        
        [cell.textField bk_addEventHandler:^(id sender) {
            // just in case this cell scrolls off the screen
            password = [cell.textField.text copy];
        } forControlEvents:UIControlEventEditingChanged];
        
        cell.textField.leftView = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 44)];
            
            label.attributedText = lockedOutline.attributedString;
            label.textAlignment = NSTextAlignmentCenter;
            label.textColor = [UIColor whiteColor];
            
            label;
        });
    }
}


- (BOOL)webView:(UIWebView *)webView shouldLoadRequest:(NSURLRequest *)request {
    if ([request.URL.path hasPrefix:@"/forgot_password"]) {
        return YES;
    }
    [self.navigationController popViewControllerAnimated:YES];
    
    static UIAlertView *av;
    if (av) {
        [av dismissWithClickedButtonIndex:0 animated:YES];
        av = nil;
    }
    
    NSString *title = NSLocalizedString(@"Check your email", @"title of alert after you reset your password");
    NSString *msg = NSLocalizedString(@"If the email address you entered is associated with an iNaturalist account, you should receive an email at that address with a link to reset your password.", @"body of alert after you reset your password");
    
    av = [[UIAlertView alloc] initWithTitle:title
                                    message:msg
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil];
    [av show];
    
    return NO;
}


/*
#pragma mark - RKRequestDelegate methods
- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response
{
    if (response.statusCode == 200 || response.statusCode == 304) {
        NSString *jsonString = [[NSString alloc] initWithData:response.body
                                                     encoding:NSUTF8StringEncoding];
        NSError* error = nil;
        id<RKParser> parser = [[RKParserRegistry sharedRegistry] parserForMIMEType:@"application/json"];
        NSDictionary *parsedData = [parser objectFromString:jsonString error:&error];
        if (parsedData == nil && error) {
            // Parser error...
            [[Analytics sharedClient] event:kAnalyticsEventLoginFailed
                             withProperties:@{ @"from": @"RKRequest Parser" }];
            
            [self failedLogin];
            return;
        }
        
        [SVProgressHUD showSuccessWithStatus:nil];
        
        NSString *userName = [parsedData objectForKey:@"login"];
        [[NSUserDefaults standardUserDefaults] setValue:userName
                                                 forKey:INatUsernamePrefKey];
        [[NSUserDefaults standardUserDefaults] setValue:[passwordField text] 
                                                 forKey:INatPasswordPrefKey];
        [[NSUserDefaults standardUserDefaults] setValue:INatAccessToken
                                                 forKey:INatTokenPrefKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        if (self.delegate && [self.delegate respondsToSelector:@selector(loginViewControllerDidLogIn:)]) {
            [self.delegate loginViewControllerDidLogIn:self];
        }
        [[self parentViewController] dismissViewControllerAnimated:YES completion:nil];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kUserLoggedInNotificationName
                                                            object:nil];
    } else {
        [[Analytics sharedClient] event:kAnalyticsEventLoginFailed
                         withProperties:@{ @"from": @"Unknown Status Code",
                                           @"code": @(response.statusCode) }];

        [self failedLogin];
    }
}
 */

/*
- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error {
    // KLUDGE!! RestKit doesn't seem to handle failed auth very well
    bool jsonParsingError = [error.domain isEqualToString:@"JKErrorDomain"] && error.code == -1;
    bool authFailure = [error.domain isEqualToString:@"NSURLErrorDomain"] && error.code == -1012;
    if (jsonParsingError || authFailure) {
        [self failedLogin];
    } else {
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:NSLocalizedString(@"Looks like there was an unexpected error: %@", @"error message with the error") , error.localizedDescription]];
    }
}

- (void)failedLogin {
    [self failedLogin:nil];
}

- (void)failedLogin:(NSString *)msg {
    //[[RKClient sharedClient] setUsername:nil];
    //[[RKClient sharedClient] setPassword:nil];
    if ([[GPPSignIn sharedInstance] hasAuthInKeychain]) [[GPPSignIn sharedInstance] disconnect];
    INaturalistAppDelegate *app = [[UIApplication sharedApplication] delegate];
    [RKClient.sharedClient setValue:nil forHTTPHeaderField:@"Authorization"];
    [app.photoObjectManager.client setValue:nil forHTTPHeaderField:@"Authorization"];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:INatUsernamePrefKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:INatPasswordPrefKey];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:INatTokenPrefKey];

    [[NSUserDefaults standardUserDefaults] synchronize];
    if (self.delegate && [self.delegate respondsToSelector:@selector(loginViewControllerFailedToLogIn:)]) {
        [self.delegate loginViewControllerFailedToLogIn:self];
    }
    
    if (!msg) {
        msg = NSLocalizedString(@"Username or password were invalid.", nil);
    }

    [SVProgressHUD showErrorWithStatus:msg];
    isLoginCompleted = YES;
}

#pragma mark UITextFieldDelegate methods
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    if (textField == usernameField) {
        [passwordField becomeFirstResponder];
    } else if (textField == passwordField) {
        [self signIn:nil];
    }
    return YES;
}

#pragma mark UITableView delegate methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        if (!av){
            av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Internet connection required",nil)
                                                     message:NSLocalizedString(@"Try again next time you're connected to the Internet.", nil)
                                                    delegate:self
                                           cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                           otherButtonTitles:nil];
            [av show];
        }
        return;
    }
    if (indexPath.section == 1) { //Facebook
        lastAssertionType = FacebookAssertionType;
        isLoginCompleted = NO;
        [SVProgressHUD showWithStatus:NSLocalizedString(@"Signing in...",nil)];
        [self openFacebookSession];
    }
    else if (indexPath.section == 2) {// Google+
        lastAssertionType = GoogleAssertionType;
        isLoginCompleted = NO;
        
        GPPSignIn *signin = [GPPSignIn sharedInstance];
        
        // GTMOAuth2VCTouch takes a different scope format than GPPSignIn
        // @"plus.login plus.me userinfo.email"
        __block NSString *scopes;
        [signin.scopes enumerateObjectsUsingBlock:^(NSString *scope, NSUInteger idx, BOOL *stop) {
            if (idx == 0)
                scopes = [NSString stringWithString:scope];
            else
                scopes = [scopes stringByAppendingString:[NSString stringWithFormat:@" %@", scope]];
        }];
        
        GooglePlusAuthViewController *vc = [GooglePlusAuthViewController controllerWithScope:scopes
                                                                                    clientID:signin.clientID
                                                                                clientSecret:nil
                                                                            keychainItemName:nil
                                                                                    delegate:self
                                                                            finishedSelector:@selector(viewController:finishedAuth:error:)];
        [self.navigationController pushViewController:vc animated:YES];
    }
    else if (indexPath.section == 3) {
        [[Analytics sharedClient] event:kAnalyticsEventNavigateSignup
                         withProperties:@{ @"from": @"Login" }];
        
        lastAssertionType = 0;
        UINavigationController *nc = self.navigationController;
        INatWebController *webController = [[INatWebController alloc] init];
        NSURL *url = [NSURL URLWithString:
                      [NSString stringWithFormat:@"%@/users/new.mobile", INatWebBaseURL]];
        [webController setUrl:url];
        webController.delegate =self;
        [nc pushViewController:webController animated:YES];
     }
    else if (indexPath.section == 4) {
        UINavigationController *nc = self.navigationController;
        INatWebController *webController = [[INatWebController alloc] init];
        NSURL *url = [NSURL URLWithString:
                      [NSString stringWithFormat:@"%@/forgot_password.mobile", INatWebBaseURL]];
        [webController setUrl:url];
        webController.delegate = self;
        [nc pushViewController:webController animated:YES];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark UIAlertViewDelegate methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    av = nil;
    if (buttonIndex == 0) return;
    NSURL *url = [NSURL URLWithString:
                  [NSString stringWithFormat:@"%@/users/new.mobile", INatWebBaseURL]];
    [[UIApplication sharedApplication] openURL:url];
}

#pragma mark - UIWebViewDelegate
- (BOOL)webView:(UIWebView *)webView shouldLoadRequest:(NSURLRequest *)request {
    if ([request.URL.path isEqualToString:@"/users"] || [request.URL.path hasPrefix:@"/users/new"] || [request.URL.path hasPrefix:@"/forgot_password"]) {
        return YES;
    }
    [self.navigationController popViewControllerAnimated:YES];
    if (av) [av dismissWithClickedButtonIndex:0 animated:YES];
    av = nil;
    NSString *title, *message;
    if ([webView.request.URL.path hasPrefix:@"/forgot_password"]) {
        title = @"Check Your Email";
        message = @"If the email address you entered is associated with an iNaturalist account, you should receive an email at that address with a link to reset your password.";
    } else {
        [[Analytics sharedClient] event:kAnalyticsEventSignup];
        title = NSLocalizedString(@"Welcome to iNaturalist!", nil);
        message = NSLocalizedString(@"Now that you've signed up you can sign in with the username and password you just created.  Don't forget to check for your confirmation email as well.", nil);
    }
    av = [[UIAlertView alloc] initWithTitle:title
                                    message:message
                                   delegate:self
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil];
    [av show];
    return NO;
}
*/

@end
