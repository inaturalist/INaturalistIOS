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

- (void)dealloc {
    [[[RKClient sharedClient] requestQueue] cancelRequestsWithDelegate:self];
}

- (IBAction)clickedCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)clickedSave:(id)sender {
    NSDictionary *params = @{
                             @"comment[body]": self.textView.text,
                             @"comment[parent_id]": @([self.observation inatRecordId]),
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
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Add Comment Failure", @"Title for add comment failed alert")
                                                                       message:NSLocalizedString(@"An unknown error occured. Please try again.", @"unknown error adding comment")
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error {
    [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Add Comment Failure", @"Title for add comment failed alert")
                                                                   message:error.localizedDescription
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];    
}

-(BOOL)prefersStatusBarHidden { return YES; }

@end
