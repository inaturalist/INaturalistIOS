//
//  ObsDetailFavesViewModel.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/18/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import <AFNetworking/UIImageView+AFNetworking.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <RestKit/RestKit.h>

#import "ObsDetailFavesViewModel.h"
#import "Observation.h"
#import "FaveVisualization.h"
#import "User.h"
#import "DisclosureCell.h"
#import "ObsDetailAddFaveHeader.h"
#import "INaturalistAppDelegate.h"
#import "LoginController.h"
#import "UIColor+INaturalist.h"
#import "NSURL+INaturalist.h"
#import "ObsDetailActivityAuthorCell.h"
#import "ObsDetailNoInteractionHeaderFooter.h"
#import "Analytics.h"
#import "UIImage+INaturalist.h"
#import "INatReachability.h"

@implementation ObsDetailFavesViewModel


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section < 2) {
        return [super tableView:tableView numberOfRowsInSection:section];
    } else {
        return self.observation.faves.count;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // plus one for the faves stuff
    return [super numberOfSectionsInTableView:tableView] + 1;
}

- (ObsDetailSection)sectionType {
    return ObsDetailSectionFaves;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section < 2) {
        return [super tableView:tableView viewForFooterInSection:section];
    } else {
        if (self.observation.inatRecordId) {
            return nil;
        } else {
            // show must login footer
            ObsDetailNoInteractionHeaderFooter *footer = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"noInteraction"];
            
            INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate  *)[[UIApplication sharedApplication] delegate];
            if (appDelegate.loginController.isLoggedIn) {
                footer.noInteractionLabel.text = NSLocalizedString(@"Upload this observation to enable faves.", nil);
            } else {
                footer.noInteractionLabel.text = NSLocalizedString(@"Login to enable faves.", nil);
            }
            
            return footer;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section < 2) {
        return [super tableView:tableView heightForFooterInSection:section];
    } else {
        if (self.observation.inatRecordId) {
            return CGFLOAT_MIN;
        } else {
            return 80;
        }
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section < 2) {
        return [super tableView:tableView viewForHeaderInSection:section];
    } else {
        if (self.observation.inatRecordId) {
            ObsDetailAddFaveHeader *header = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"addFave"];
            
            header.faved = [self loggedInUserHasFavedThisObservation];
            header.faveCount = self.observation.faves.count;
            
            [header.faveContainer addTarget:self
                                     action:@selector(tappedFave:)
                           forControlEvents:UIControlEventTouchUpInside];
            
            return header;
        } else {
            return nil;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section < 2) {
        return [super tableView:tableView heightForHeaderInSection:section];
    } else {
        if (self.observation.inatRecordId) {
            return 69;
        } else {
            return CGFLOAT_MIN;
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < 2) {
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    } else {
        ObsDetailActivityAuthorCell *cell = [tableView dequeueReusableCellWithIdentifier:@"activityAuthor"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        id <FaveVisualization> fave = [self.observation.sortedFaves objectAtIndex:indexPath.item];
        if ([fave userIconUrl]) {
            [cell.authorImageView setImageWithURL:[fave userIconUrl]];
            cell.authorImageView.layer.cornerRadius = 27.0 / 2;
            cell.authorImageView.clipsToBounds = YES;
        } else {
            cell.authorImageView.image = [UIImage inat_defaultUserImage];
        }
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        
        dateFormatter.dateStyle = NSDateFormatterShortStyle;
        dateFormatter.timeStyle = NSDateFormatterNoStyle;
        
        dateFormatter.doesRelativeDateFormatting = YES;
        
        cell.authorNameLabel.text = [fave userName];
        cell.dateLabel.text = [dateFormatter stringFromDate:[fave createdAt]];
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < 2) {
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    }
}

- (void)tappedFave:(UIControl *)control {
    if (![[INatReachability sharedClient] isNetworkReachable]) {
        [self.delegate noticeWithTitle:NSLocalizedString(@"Can't Fave", nil)
                               message:NSLocalizedString(@"Network is required.", @"Network is required error message")];
        return;
    }
    
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (!appDelegate.loginController.isLoggedIn) {
        [self.delegate noticeWithTitle:NSLocalizedString(@"Can't Fave", nil)
                               message:NSLocalizedString(@"You must be logged in.", @"Account is required error message")];
        return;
    }
    
    NSString *requestPath = nil;
    NSString *hudText;
    NSString *method;
    
    if ([self loggedInUserHasFavedThisObservation]) {
        // need to unfave it
        [[Analytics sharedClient] event:kAnalyticsEventObservationUnfave];
        
        // delete to /votes/unvote/observation/{obs.recordID}.json
        requestPath = [NSString stringWithFormat:@"/votes/unvote/observation/%ld.json", (long)self.observation.inatRecordId];
        hudText = NSLocalizedString(@"Un-faving...", nil);
        method = @"DELETE";
    } else {
        // need to fave it
        [[Analytics sharedClient] event:kAnalyticsEventObservationFave];
        
        // post to /votes/vote/observation/{obs.recordID}.json
        requestPath = [NSString stringWithFormat:@"/votes/vote/observation/%ld.json", (long)self.observation.inatRecordId];
        hudText = NSLocalizedString(@"Faving...", nil);
        method = @"POST";
    }
    
    NSURL *requestURL = [NSURL URLWithString:requestPath relativeToURL:[NSURL inat_baseURL]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL];
    [request setHTTPMethod:method];
    
    [request addValue:[[NSUserDefaults standardUserDefaults] stringForKey:INatTokenPrefKey]
   forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/json" forHTTPHeaderField:@"content-type"];
    
    [self.delegate showProgressHud];
    
    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request
                                                             completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                 
                                                                 [self.delegate hideProgressHud];
                                                                 
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
    if (self.observation.faves.count < 1) {
        return NO;
    }
    
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    LoginController *login = appDelegate.loginController;
    if (login.isLoggedIn) {
        for (id <FaveVisualization> fave in self.observation.faves) {
            if ([[fave userName] isEqualToString:[[login fetchMe] login]]) {
                return YES;
            }
        }
    }
    return NO;
}

@end
