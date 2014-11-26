//
//  AddCommentViewController.m
//  iNaturalist
//
//  Created by Ryan Waggoner on 10/23/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import "AddCommentViewController.h"
#import "Observation.h"
#import "DejalActivityView.h"
#import "Analytics.h"

@interface AddCommentViewController () <RKRequestDelegate>

@property (weak, nonatomic) IBOutlet UITextView *textView;

- (IBAction)clickedCancel:(id)sender;
- (IBAction)clickedSave:(id)sender;

@end

@implementation AddCommentViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBar.translucent = NO;
	[super viewWillAppear:animated];
	[self.textView becomeFirstResponder];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[Analytics sharedClient] timedEvent:kAnalyticsEventNavigateAddComment];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[Analytics sharedClient] endTimedEvent:kAnalyticsEventNavigateAddComment];
}

- (IBAction)clickedCancel:(id)sender {
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)clickedSave:(id)sender {
	[DejalBezelActivityView activityViewForView:self.view withLabel:NSLocalizedString(@"Saving...",nil)];
	NSDictionary *params = @{
							 @"comment[body]": self.textView.text,
							 @"comment[parent_id]": self.observation.recordID,
							 @"comment[parent_type]": @"Observation"
							 };
	[[RKClient sharedClient] post:@"/comments" params:params delegate:self];
}

- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response
{
	[DejalBezelActivityView removeView];
	NSLog(@"Response: %@", response);
	if (response.statusCode == 200) {
		[self dismissViewControllerAnimated:YES completion:nil];
	} else {
		[self showError:@"An unknown error occurred. Please try again."];
	}
}

- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error
{
	[DejalBezelActivityView removeView];
	NSLog(@"Request Error: %@", error.localizedDescription);
	[self showError:error.localizedDescription];
}

- (void)showError:(NSString *)errorMessage{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:errorMessage delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
}

-(BOOL)prefersStatusBarHidden { return YES; }

@end
