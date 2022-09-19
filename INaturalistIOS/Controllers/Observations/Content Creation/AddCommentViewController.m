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
#import "CommentsAPI.h"
#import "INaturalistAppDelegate.h"
#import "LoginController.h"

@interface AddCommentViewController ()

@property (weak, nonatomic) IBOutlet UITextView *textView;

- (IBAction)clickedCancel:(id)sender;
- (IBAction)clickedSave:(id)sender;

@end

@implementation AddCommentViewController

- (CommentsAPI *)commentsApi {
    static CommentsAPI *_api = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _api = [[CommentsAPI alloc] init];
    });
    return _api;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.translucent = NO;
    [self.textView becomeFirstResponder];
    self.textView.textAlignment = NSTextAlignmentNatural;
}

- (IBAction)clickedCancel:(id)sender {
    [self.onlineEditingDelegate editorCancelled];
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

    __weak typeof(self) weakSelf = self;    
    // send the comment
    [[self commentsApi] addComment:self.textView.text
                     observationId:self.observation.inatRecordId
                           handler:^(NSArray *results, NSInteger count, NSError *error) {
        
        __strong typeof (weakSelf) strongSelf = weakSelf;
        
        // hide the hud regardless of success
        [MBProgressHUD hideAllHUDsForView:strongSelf.view animated:YES];
        
        if (error) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Add Comment Failure", @"Title for add comment failed alert")
                                                                           message:error.localizedDescription
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            [strongSelf presentViewController:alert animated:YES completion:nil];
        } else {
            [strongSelf.onlineEditingDelegate editorEditedObservationOnline];
        }
    }];
}

-(BOOL)prefersStatusBarHidden { return YES; }

@end
