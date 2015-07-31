//
//  ProjectDetailViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/27/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <TapkuLibrary/TapkuLibrary.h>
#import <SVProgressHUD/SVProgressHUD.h>
#import <SDWebImage/UIImageView+WebCache.h>

#import "ProjectDetailViewController.h"
#import "INaturalistAppDelegate.h"
#import "UIColor+INaturalist.h"
#import "Analytics.h"
#import "SignupSplashViewController.h"
#import "INaturalistAppDelegate+TransitionAnimators.h"
#import "UIImage+INaturalist.h"
#import "INatWebController.h"

static const int LeaveProjectAlertViewTag = 1;

@implementation ProjectDetailViewController
@synthesize project = _project;
@synthesize projectUser = _projectUser;
@synthesize sectionHeaderViews = _sectionHeaderViews;
@synthesize projectIcon = _projectIcon;
@synthesize joinButton = _joinButton;
@synthesize projectTitle = _projectTitle;

- (void)setProject:(Project *)project
{
    _project = project;
    self.projectUser = [ProjectUser objectWithPredicate:[NSPredicate predicateWithFormat:@"projectID = %@", project.recordID]];
}

- (void)setProjectUser:(ProjectUser *)projectUser
{
    _projectUser = projectUser;
    if (self.joinButton) {
        [self setupJoinButton];
    }
}

- (void)setupJoinButton
{
    if (self.projectUser && ![self.projectUser isNew]) {
        self.joinButton.title = NSLocalizedString(@"Leave",nil);
        self.joinButton.tintColor = [UIColor blackColor];
    } else {
        self.joinButton.title = NSLocalizedString(@"Join",nil);
        self.joinButton.tintColor = [UIColor colorWithRed:155/255.0 
                                                    green:196/255.0 
                                                     blue:48/255.0 
                                                    alpha:1];
    }
}

- (IBAction)clickedViewButton:(id)sender {
    NSString *countryCode = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    NSString *url =[NSString stringWithFormat:@"%@/projects/%@?locale=%@-%@",
                    INatWebBaseURL, self.project.cachedSlug, language, countryCode];
    
    INatWebController *web = [[INatWebController alloc] initWithNibName:nil bundle:nil];
    web.url = [NSURL URLWithString:url];
    [self.navigationController pushViewController:web animated:YES];
}

- (IBAction)clickedJoin:(id)sender {
    if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Internet required",nil)
                                                     message:NSLocalizedString(@"You must be connected to the Internet to do this.",nil)
                                                    delegate:self 
                                           cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                           otherButtonTitles:nil];
        [av show];
        return;
    }
    if (self.projectUser && self.projectUser.syncedAt) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Are you sure you want to leave this project?",nil)
                                                     message:NSLocalizedString(@"This will also remove your observations from this project.",nil)
                                                    delegate:self 
                                           cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                           otherButtonTitles:NSLocalizedString(@"Leave",nil), nil];
        av.tag = LeaveProjectAlertViewTag;
        [av show];
    } else {
        if ([(INaturalistAppDelegate *)UIApplication.sharedApplication.delegate loggedIn]) {
            [self join];
        } else {
            [[Analytics sharedClient] event:kAnalyticsEventNavigateSignupSplash
                             withProperties:@{ @"From": @"Project Detail" }];

            SignupSplashViewController *signup = [[SignupSplashViewController alloc] initWithNibName:nil bundle:nil];
            signup.reason = NSLocalizedString(@"You must be signed in to join a project.", @"Reason text for signup prompt while trying to join a project.");
            signup.cancellable = YES;
            signup.skippable = NO;
            UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:signup];
            nav.delegate = (INaturalistAppDelegate *)[UIApplication sharedApplication].delegate;
            [self presentViewController:nav animated:YES completion:nil];
        }
    }
}

- (IBAction)clickedClose:(id)sender {
    [[self parentViewController] dismissViewControllerAnimated:YES completion:nil];
}

- (void)join
{
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Joining...",nil)];
    if (!self.projectUser) {
        self.projectUser = [ProjectUser object];
        self.projectUser.project = self.project;
        self.projectUser.projectID = self.project.recordID;
    }
    [[Analytics sharedClient] debugLog:@"Network - Join a project"];
    [[RKObjectManager sharedManager] postObject:self.projectUser usingBlock:^(RKObjectLoader *loader) {
        loader.delegate = self;
        loader.resourcePath = [NSString stringWithFormat:@"/projects/%d/join", self.project.recordID.intValue];
        loader.objectMapping = [ProjectUser mapping];
    }];
}

- (void)leave
{
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Leaving...",nil)];
    [[Analytics sharedClient] debugLog:@"Network - Leave a project"];
    [[RKObjectManager sharedManager] deleteObject:self.projectUser usingBlock:^(RKObjectLoader *loader) {
        loader.delegate = self;
        loader.resourcePath = [NSString stringWithFormat:@"/projects/%d/leave", self.project.recordID.intValue];
    }];
}

- (NSString *)projectDescription
{
    if (self.project && self.project.desc && self.project.desc.length != 0) {
        return [self.project.desc stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
    } else {
        return NSLocalizedString(@"No description.", nil);
    }
}

- (NSString *)projectTerms
{
    if (self.project && self.project.terms && self.project.terms.length != 0) {
        return [self.project.terms stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
    } else {
        return NSLocalizedString(@"No terms.", nil);
    }
}

#pragma mark - View lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];

    [self.projectIcon sd_setImageWithURL:[NSURL URLWithString:self.project.iconURL]
                        placeholderImage:[UIImage inat_defaultProjectImage]];
    self.projectTitle.text = self.project.title;
    
    CAGradientLayer *lyr = [CAGradientLayer layer];
    lyr.colors = [NSArray arrayWithObjects:
                  (id)[UIColor whiteColor].CGColor, 
                  (id)[UIColor colorWithRed:(220/255.0)  green:(220/255.0)  blue:(220/255.0)  alpha:1.0].CGColor, nil];
    lyr.locations = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0], [NSNumber numberWithFloat:1], nil];
    lyr.frame = self.tableView.tableHeaderView.bounds;
    [self.tableView.tableHeaderView.layer insertSublayer:lyr atIndex:0];
    
    [self setupJoinButton];
    NSString *currentLanguage = [[NSLocale preferredLanguages] objectAtIndex:0];
    if ([currentLanguage isEqualToString:@"es"]) {
        NSDictionary *attrs = @{
                                NSFontAttributeName: [UIFont boldSystemFontOfSize:17],
                                };
        self.navigationController.navigationBar.titleTextAttributes = attrs;
    }
    // Adding auto layout for header view.
    [self setupConstraintsForHeader];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setToolbarHidden:YES animated:animated];
    self.navigationController.navigationBar.translucent = NO;
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor inatTint];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[Analytics sharedClient] timedEvent:kAnalyticsEventNavigateProjectDetail];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[Analytics sharedClient] endTimedEvent:kAnalyticsEventNavigateProjectDetail];
}

- (NSInteger)heightForHTML:(NSString *)html
{
    NSString *s = [html stringByReplacingOccurrencesOfString:@"<br>" withString:@"\n"];
    s = [s stringByReplacingOccurrencesOfString:@"<BR>" withString:@"\n"];
    s = [s stringByReplacingOccurrencesOfString:@"<p>" withString:@""];
    s = [s stringByReplacingOccurrencesOfString:@"</p>" withString:@"\n"];
    s = [s stringByRemovingHTML];
    s = [s stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
    CGSize size = [s sizeWithFont:[UIFont systemFontOfSize:15] 
                    constrainedToSize:CGSizeMake(320, 1000) 
                    lineBreakMode:NSLineBreakByWordWrapping];
    return size.height;
}

#pragma mark - Table view delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row == 0) {
        return [self heightForHTML:[self projectDescription]] + 10;
    } else if (indexPath.section == 1 && indexPath.row == 0) {
        return [self heightForHTML:[self projectTerms]] + 10;
    } else if (indexPath.section == 2 && indexPath.row == 0) {
        NSArray *terms = [self.project.projectObservationRuleTerms componentsSeparatedByString:@"|"];
        NSString *first;
        if (self.project.projectObservationRuleTerms && self.project.projectObservationRuleTerms.length > 0) {
            first = [terms objectAtIndex:0];
        } else {
            first = [NSString stringWithString:NSLocalizedString(@"No observation rules",nil)];
        }
        CGSize s = [first sizeWithFont:[UIFont systemFontOfSize:15] 
                     constrainedToSize:CGSizeMake(320, 1000) 
                         lineBreakMode:NSLineBreakByWordWrapping];
        return s.height * terms.count + 10;
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (!self.sectionHeaderViews) {
        self.sectionHeaderViews = [[NSMutableDictionary alloc] init];
    }
    NSNumber *key = @(section);
    if ([self.sectionHeaderViews objectForKey:key]) {
        return [self.sectionHeaderViews objectForKey:key];
    }
    
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 30)];
    header.backgroundColor = [UIColor whiteColor];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 300, 20)];
    label.font = [UIFont boldSystemFontOfSize:17];
    label.textColor = [UIColor darkGrayColor];
    label.textAlignment = NSTextAlignmentNatural;
    switch (section) {
        case 0:
            label.text = NSLocalizedString(@"Description",nil);
            break;
        case 1:
            label.text = NSLocalizedString(@"Terms",nil);
            break;
        case 2:
            label.text = NSLocalizedString(@"Observation Rules",nil);
            break;
        default:
            break;
    }
    [header addSubview:label];
    
    [self.sectionHeaderViews setObject:header forKey:key];
    return header;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    UILabel *rowContent;
    NSString *divAlignment = [self divAlignmentForCurrentLanguage];
    if (indexPath.section == 0 && indexPath.row == 0) {
        rowContent = (UILabel *)[cell viewWithTag:1];
        // Adding auto layout to support RTL for sizeToFit
        [self setupConstraintsForCell:cell andLabel:rowContent];
        if (!rowContent.text) {
            NSString *htmlString = [NSString stringWithFormat:@"<div style='text-align:%@;'>%@</div>",divAlignment, [self projectDescription]];
            
            rowContent.attributedText = [[NSAttributedString alloc] initWithData:[htmlString dataUsingEncoding:NSUTF8StringEncoding]
                                                                         options:@{
                                                                                   NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                                                                   NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)
                                                                                   }
                                                              documentAttributes:nil
                                                                           error:nil];
            [rowContent sizeToFit];
            rowContent.backgroundColor = [UIColor whiteColor];
            rowContent.numberOfLines = 0;
        }
    } else if (indexPath.section == 1 && indexPath.row == 0) {
        rowContent = (UILabel *)[cell viewWithTag:1];
        // Adding auto layout to support RTL for sizeToFit
        [self setupConstraintsForCell:cell andLabel:rowContent];
        if (!rowContent.text) {
            NSString *htmlString = [NSString stringWithFormat:@"<div style='text-align:%@;'>%@</div>",divAlignment, [self projectTerms]];
            
            rowContent.attributedText = [[NSAttributedString alloc] initWithData:[htmlString dataUsingEncoding:NSUTF8StringEncoding]
                                                                         options:@{
                                                                                   NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                                                                   NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)
                                                                                   }
                                                              documentAttributes:nil
                                                                           error:nil];
            
            [rowContent sizeToFit];
            rowContent.backgroundColor = [UIColor whiteColor];
            rowContent.numberOfLines = 0;
        }
    } else if (indexPath.section == 2 && indexPath.row == 0) {
        rowContent = (UILabel *)[cell viewWithTag:2];
        // Adding auto layout to support RTL for sizeToFit.
        [self setupConstraintsForCell:cell andLabel:rowContent];
        if (!rowContent.text) {
            NSArray *terms = [self.project.projectObservationRuleTerms componentsSeparatedByString:@"|"];
            NSMutableString *termsString;
            if (self.project.projectObservationRuleTerms && self.project.projectObservationRuleTerms.length > 0) {
                termsString = [NSMutableString stringWithFormat:@"<div style='text-align:%@;'><ul>",divAlignment];
                for (NSString *term in terms) {
                    [termsString appendString:[NSString stringWithFormat:@"\n<li>- %@</li>", term]];
                }
                [termsString appendString:@"</ul></div>"];
            } else {
                termsString = [NSMutableString stringWithFormat:@"<div style='text-align:%@;'>%@.</div>",divAlignment, NSLocalizedString(@"No observation rules", nil)];
            }
            
            rowContent.attributedText = [[NSAttributedString alloc] initWithData:[termsString dataUsingEncoding:NSUTF8StringEncoding]
                                                                         options:@{
                                                                                   NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                                                                   NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)
                                                                                   }
                                                              documentAttributes:nil
                                                                           error:nil];
            [rowContent sizeToFit];
            rowContent.backgroundColor = [UIColor whiteColor];
            rowContent.numberOfLines = 0;
        }
    }
    return cell;
}

#pragma mark - ScrollViewDelegate
// This is necessary to stop the section headers from sticking to the top of the screen
// http://stackoverflow.com/questions/664781/change-default-scrolling-behavior-of-uitableview-section-header
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat sectionHeaderHeight = 30;
    if (scrollView.contentOffset.y <= sectionHeaderHeight && scrollView.contentOffset.y >= 0) {
        scrollView.contentInset = UIEdgeInsetsMake(-scrollView.contentOffset.y, 0, 0, 0);
    } else if (scrollView.contentOffset.y>=sectionHeaderHeight) {
        scrollView.contentInset = UIEdgeInsetsMake(-sectionHeaderHeight, 0, 0, 0);
    }
}

#pragma mark - RKObjectLoader
- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObject:(id)object
{
    ProjectUser *pu = object;
    if (pu) {
        pu.syncedAt = [NSDate date];
        [pu save];
        [self clickedClose:nil];
    }
    self.projectUser = pu;
    [SVProgressHUD showSuccessWithStatus:nil];
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error
{
    [SVProgressHUD dismiss];
    if (objectLoader.response.statusCode == 401) {
        [[Analytics sharedClient] event:kAnalyticsEventNavigateSignupSplash
                         withProperties:@{ @"From": @"Project Detail" }];

        SignupSplashViewController *signup = [[SignupSplashViewController alloc] initWithNibName:nil bundle:nil];
        signup.reason = NSLocalizedString(@"You must be signed in to do that.", @"Reason text for signup prompt while trying to sync a project.");
        signup.cancellable = YES;
        signup.skippable = NO;
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:signup];
        nav.delegate = (INaturalistAppDelegate *)[UIApplication sharedApplication].delegate;
        [self presentViewController:nav animated:YES completion:nil];
    } else {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Whoops!",nil)
                                                     message:[NSString stringWithFormat:NSLocalizedString(@"Looks like there was an error: %@",nil), error.localizedDescription]
                                                    delegate:self 
                                           cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                           otherButtonTitles:nil];
        [av show];
    }
}

#pragma mark - LoginViewControllerDelegate
/*
 - (void)loginViewControllerDidLogIn:(LoginViewController *)controller
{
    [self clickedJoin:nil];
}

- (void)loginViewControllerDidCancel:(LoginViewController *)controller
{
    if (self.projectUser) {
        [self.projectUser destroy];
    }
}
 */

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag != LeaveProjectAlertViewTag) {
        return;
    }
    
    if (buttonIndex == 1) {
        [self leave];
    }
}


- (void)setupConstraintsForHeader{
    self.projectIcon.translatesAutoresizingMaskIntoConstraints = NO;
    self.projectTitle.translatesAutoresizingMaskIntoConstraints = NO;
    self.projectTitle.textAlignment = NSTextAlignmentNatural;
    
    NSDictionary *views = @{@"projectIcon":self.projectIcon, @"projectTitle":self.projectTitle};
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-5-[projectIcon(==70)]-[projectTitle]-10-|" options:0 metrics:0 views:views]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[projectIcon(==70)]" options:NSLayoutFormatAlignAllLeading metrics:0 views:views]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[projectTitle]-5-|" options:0 metrics:0 views:views]];
}


/*!
 * Adding auto layout to support RTL for sizeToFit.
 */
- (void)setupConstraintsForCell:(UITableViewCell *)cell andLabel:(UILabel *)label{
    if(!label.constraints.count){
        label.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSDictionary *views = @{@"label":label};
        
        [cell addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-5-[label]-5-|" options:0 metrics:0 views:views]];
        
        [cell addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-5-[label]-5-|" options:NSLayoutFormatAlignAllLeading metrics:0 views:views]];
        
    }
}

/*!
 * Get the alignment for div based on current language.
 */
- (NSString *)divAlignmentForCurrentLanguage{
    NSLocaleLanguageDirection currentLanguageDirection = [NSLocale characterDirectionForLanguage:[[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode]];
    if(currentLanguageDirection == kCFLocaleLanguageDirectionRightToLeft)
        return @"right";
    
    return @"left";
}




@end











