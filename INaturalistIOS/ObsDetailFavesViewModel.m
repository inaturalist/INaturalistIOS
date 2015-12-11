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
#import "ObsDetailActivityAuthorCell.h"

@implementation ObsDetailFavesViewModel


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section < 2) {
        return [super tableView:tableView numberOfRowsInSection:section];
    } else {
        // 1 for the fave/unfave button
        return 1 + [[self.observation faves] count];
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [super numberOfSectionsInTableView:tableView] + 1;
}

- (ObsDetailSection)sectionType {
    return ObsDetailSectionFaves;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < 2) {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    } else {
        if (indexPath.item == 0) {
            return 69;
        } else {
            return 44;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < 2) {
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    } else {
        if (indexPath.item == 0) {
            // fave/unfave button
            // fave button
            AddFaveCell *cell = [tableView dequeueReusableCellWithIdentifier:@"addFave"];
            cell.faveCountLabel.text = [NSString stringWithFormat:@"%ld", (unsigned long)self.observation.sortedFaves.count];
            [cell setFaved:[self loggedInUserHasFavedThisObservation]];
            
            return cell;
        } else {
            ObsDetailActivityAuthorCell *cell = [tableView dequeueReusableCellWithIdentifier:@"activityAuthor"];
            
            Fave *fave = [self.observation.sortedFaves objectAtIndex:indexPath.item - 1];
            NSURL *userIconUrl = [NSURL URLWithString:fave.userIconUrl];
            if (userIconUrl) {
                [cell.authorImageView sd_setImageWithURL:userIconUrl];
                cell.authorImageView.layer.cornerRadius = 27.0 / 2;
                cell.authorImageView.clipsToBounds = YES;
            }
            NSDateFormatter *dateFormatter = [NSDateFormatter new];
            
            dateFormatter.dateStyle = NSDateFormatterShortStyle;
            dateFormatter.timeStyle = NSDateFormatterNoStyle;
            
            dateFormatter.doesRelativeDateFormatting = YES;
            
            cell.authorNameLabel.text = fave.userLogin;
            cell.dateLabel.text = [dateFormatter stringFromDate:fave.faveDate];
            
            return cell;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < 2) {
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    } else if (indexPath.item == 0) {
        
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
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:tableView.superview animated:YES];
        hud.removeFromSuperViewOnHide = YES;
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
}

- (BOOL)loggedInUserHasFavedThisObservation {
    if (self.observation.faves.count < 1) {
        return NO;
    }
    
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    LoginController *login = appDelegate.loginController;
    if (login.isLoggedIn) {
        for (Fave *fave in self.observation.faves) {
            if ([fave.userLogin isEqualToString:[[login fetchMe] login]]) {
                return YES;
            }
        }
    }
    return NO;
}

@end
