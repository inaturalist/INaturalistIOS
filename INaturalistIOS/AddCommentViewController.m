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
#import "CommentsAPI.h"
#import "INaturalistAppDelegate.h"
#import "LoginController.h"

@interface AddCommentViewController ()

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

- (IBAction)clickedCancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)clickedSave:(id)sender {
    // minimum validation for the textview is 2 characters?
    if (self.textView.text.length < 2) {
        return;
    }
    
    // show a progress hud
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.removeFromSuperViewOnHide = YES;
    hud.dimBackground = YES;
    hud.labelText = NSLocalizedString(@"Saving...", nil);

    CommentsAPI *api = [[CommentsAPI alloc] init];
    __weak typeof(self) weakSelf = self;
    
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    // send the comment
    [api addComment:self.textView.text observationId:self.observation.inatRecordId handler:^(NSArray *results, NSInteger count, NSError *error) {
        // hide the hud regardless of success
        [MBProgressHUD hideAllHUDsForView:weakSelf.view animated:YES];
        
        if (error) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Add Comment Failure", @"Title for add comment failed alert")
                                                                           message:error.localizedDescription
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            [weakSelf presentViewController:alert animated:YES completion:nil];
        } else {
            [weakSelf dismissViewControllerAnimated:YES completion:nil];
            
        }
    }];
}

-(BOOL)prefersStatusBarHidden { return YES; }

@end
