//
//  AddCommentViewController.m
//  iNaturalist
//
//  Created by Ryan Waggoner on 10/23/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import <MBProgressHUD/MBProgressHUD.h>

#import "AddCommentViewController.h"
#import "Observation.h"
#import "Analytics.h"

@interface AddCommentViewController () <RKRequestDelegate>

@property (weak, nonatomic) IBOutlet UITextView *textView;

- (IBAction)clickedCancel:(id)sender;
- (IBAction)clickedSave:(id)sender;

@end

@implementation AddCommentViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.translucent = NO;
	[self.textView becomeFirstResponder];
    self.textView.textAlignment = NSTextAlignmentNatural;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[Analytics sharedClient] timedEvent:kAnalyticsEventNavigateAddComment];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[Analytics sharedClient] endTimedEvent:kAnalyticsEventNavigateAddComment];
}

- (void)dealloc {
    [[[RKClient sharedClient] requestQueue] cancelRequestsWithDelegate:self];
}

- (IBAction)clickedCancel:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)clickedSave:(id)sender {
	NSDictionary *params = @{
							 @"comment[body]": self.textView.text,
							 @"comment[parent_id]": self.observation.recordID,
							 @"comment[parent_type]": @"Observation"
							 };
    [[Analytics sharedClient] debugLog:@"Network - Post Comment"];

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.removeFromSuperViewOnHide = YES;
    hud.dimBackground = YES;
    hud.labelText = NSLocalizedString(@"Saving...", nil);
	[[RKClient sharedClient] post:@"/comments" params:params delegate:self];
}

- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response {
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    
	if (response.statusCode == 200) {
		[self dismissViewControllerAnimated:YES completion:nil];
	} else {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add Comment Failure", @"Title for add comment failed alert")
                                    message:NSLocalizedString(@"An unknown error occured. Please try again.", @"unknown error adding comment")
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil] show];
	}
}

- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error {
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add Comment Failure", @"Title for add comment failed alert")
                                message:error.localizedDescription
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"OK", nil)
                      otherButtonTitles:nil] show];
}

-(BOOL)prefersStatusBarHidden { return YES; }

@end
