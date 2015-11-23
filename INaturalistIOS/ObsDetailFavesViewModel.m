//
//  ObsDetailFavesViewModel.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/18/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>
#import <MBProgressHUD/MBProgressHUD.h>

#import "ObsDetailFavesViewModel.h"
#import "Observation.h"
#import "Fave.h"
#import "User.h"
#import "DisclosureCell.h"
#import "AddFaveCell.h"
#import "INaturalistAppDelegate.h"
#import "LoginController.h"
#import "UIColor+INaturalist.h"
#import "NSURL+INaturalist.h"

@implementation ObsDetailFavesViewModel


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 5 + [[self.observation faves] count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (ObsDetailSection)sectionType {
    return ObsDetailSectionFaves;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.item < 4) {
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    } else if (indexPath.item == 4) {
        // fave button
        AddFaveCell *cell = [tableView dequeueReusableCellWithIdentifier:@"addFave"];
        
        if ([self loggedInUserHasFavedThisObservation]) {
            [cell.addFaveButton setTitle:@"Faved" forState:UIControlStateNormal];
            cell.addFaveButton.backgroundColor = [UIColor inatTint];
            [cell.addFaveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        } else {
            [cell.addFaveButton setTitle:@"Add to Favorites" forState:UIControlStateNormal];
            cell.addFaveButton.backgroundColor = [UIColor whiteColor];
            cell.addFaveButton.tintColor = [UIColor inatTint];
            cell.addFaveButton.titleLabel.textColor = [UIColor inatTint];
            [cell.addFaveButton setTitleColor:[UIColor inatTint] forState:UIControlStateNormal];
        }
        
        [cell.addFaveButton addTarget:self
                               action:@selector(addFavePressed:)
                     forControlEvents:UIControlEventTouchUpInside];
        
        return cell;

    } else {
    
        DisclosureCell *cell = [tableView dequeueReusableCellWithIdentifier:@"disclosure"];
        
        if (self.observation.sortedFaves.count == self.observation.favesCount.integerValue) {
            Fave *fave = [self.observation.sortedFaves objectAtIndex:indexPath.item - 5];
            NSURL *userIconUrl = [NSURL URLWithString:fave.userIconUrl];
            if (userIconUrl) {
                [cell.cellImageView sd_setImageWithURL:userIconUrl];
                cell.cellImageView.layer.cornerRadius = 27.0 / 2;
                cell.cellImageView.clipsToBounds = YES;
            }
            NSDateFormatter *dateFormatter = [NSDateFormatter new];
            
            dateFormatter.dateStyle = NSDateFormatterShortStyle;
            dateFormatter.timeStyle = NSDateFormatterNoStyle;
            
            dateFormatter.doesRelativeDateFormatting = YES;
            
            cell.titleLabel.text = fave.userLogin;
            cell.secondaryLabel.text = [dateFormatter stringFromDate:fave.faveDate];
        } else {
            cell.titleLabel.text = @"Loading...";
        }
        return cell;
    }
}


- (void)addFavePressed:(UIButton *)button {
    
    NSString *requestPath = nil;
    NSString *hudText;
    NSString *method;
    
    if ([self loggedInUserHasFavedThisObservation]) {
        // need to unfave it
        // delete to /votes/unvote/observation/{obs.recordID}.json
        requestPath = [NSString stringWithFormat:@"/votes/unvote/observation/%ld.json", (long)self.observation.recordID.integerValue];
        hudText = NSLocalizedString(@"Un-faving...", nil);
        method = @"DELETE";
    } else {
        // need to fave it
        // post to /votes/vote/observation/{obs.recordID}.json
        requestPath = [NSString stringWithFormat:@"/votes/vote/observation/%ld.json", (long)self.observation.recordID.integerValue];
        hudText = NSLocalizedString(@"Faving...", nil);
        method = @"POST";
    }
    
    NSURL *requestURL = [NSURL URLWithString:requestPath relativeToURL:[NSURL inat_baseURL]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
    [request setHTTPMethod:method];

    [request addValue:[[NSUserDefaults standardUserDefaults] stringForKey:INatTokenPrefKey]
   forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:button.superview.superview.superview animated:YES];
    hud.removeFromSuperViewOnHide =
    hud.dimBackground = YES;
    
    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                             completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                 
                                                                 dispatch_async(dispatch_get_main_queue(), ^{
                                                                     [hud hide:YES];
                                                                 });
                                                                 
                                                                 if (error) {
                                                                     NSLog(@"dataTaskWithRequest error: %@", error);
                                                                 }
                                                                 
                                                                 if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                                                                     NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
                                                                     if (statusCode != 200) {
                                                                         NSLog(@"Expected responseCode == 200; received %ld", (long)statusCode);
                                                                     }
                                                                 }
                                                                 
                                                                 [self.delegate reloadObservation];
                                                             }];
    [task resume];
    
}

- (BOOL)loggedInUserHasFavedThisObservation {
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    LoginController *login = appDelegate.loginController;
    if (login.isLoggedIn) {
        if (self.observation.faves.count > 0) {
            for (Fave *fave in self.observation.faves) {
                if (fave.userLogin == [[login fetchMe] login]) {
                    return YES;
                }
            }
        }
    }
    return NO;
}

@end
