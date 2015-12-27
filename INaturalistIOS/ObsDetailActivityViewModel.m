//
//  ObsDetailActivityViewModel.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/18/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>
#import <UIColor-HTMLColors/UIColor+HTMLColors.h>
#import <MBProgressHUD/MBProgressHUD.h>

#import "ObsDetailActivityViewModel.h"
#import "Observation.h"
#import "Comment.h"
#import "Identification.h"
#import "DisclosureCell.h"
#import "User.h"
#import "Activity.h"
#import "Taxon.h"
#import "ImageStore.h"
#import "TaxonPhoto.h"
#import "ObsDetailActivityMoreCell.h"
#import "UIColor+INaturalist.h"
#import "ObsDetailActivityAuthorCell.h"
#import "ObsDetailActivityBodyCell.h"
#import "ObsDetailAddActivityFooter.h"
#import "ObsDetailTaxonCell.h"
#import "INaturalistAppDelegate.h"
#import "LoginController.h"
#import "NSURL+INaturalist.h"
#import "Analytics.h"

@interface ObsDetailActivityViewModel () <RKRequestDelegate>
@end

@implementation ObsDetailActivityViewModel

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section < 2) {
        return [super tableView:tableView numberOfRowsInSection:section];
    } else {
        if (self.observation.sortedActivity.count == 0) {
            // if activity hasn't been loaded from the server yet
            return 0;
        }
        Activity *activity = [self activityForSection:section];
        if ([activity isKindOfClass:[Comment class]]) {
            return 2;
        } else if ([activity isKindOfClass:[Identification class]]) {
            Identification *identification = (Identification *)activity;
            if (identification.body && identification.body.length > 0) {
                return 4;
            } else {
                return 3;
            }
        } else {
            // impossibru
            return 0;
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // each comment/id is its own section
    return [super numberOfSectionsInTableView:tableView] + self.observation.sortedActivity.count;
}

- (Activity *)activityForSection:(NSInteger)section {
    // first 2 sections are for is observation metadata
    return self.observation.sortedActivity[section - 2];
}

- (ObsDetailSection)sectionType {
    return ObsDetailSectionActivity;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section < 2) {
        return [super tableView:tableView heightForHeaderInSection:section];
    } else if (section == 2) {
        return 0;
    } else {
        return 30;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (section == self.observation.sortedActivity.count + 1) {
        return 64;
    } else {
        return CGFLOAT_MIN;
    }
}


- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    if (section == self.observation.sortedActivity.count + 1) {
        ObsDetailAddActivityFooter *footer = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"addActivityFooter"];
        [footer.commentButton addTarget:self
                                 action:@selector(addComment)
                       forControlEvents:UIControlEventTouchUpInside];
        [footer.suggestIDButton addTarget:self
                                   action:@selector(addIdentification)
                         forControlEvents:UIControlEventTouchUpInside];
        return footer;
    } else {
        return nil;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < 2) {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    } else {
        Activity *activity = [self activityForSection:indexPath.section];
        if ([activity isKindOfClass:[Comment class]]) {
            if (indexPath.item == 0) {
                // size for user/date
                return 44;
            } else {
                // body row
                return [self heightForRowInTableView:tableView withBodyText:activity.body];
            }
        } else {
            // identification
            if ([self tableView:tableView numberOfRowsInSection:indexPath.section] == 4) {
                // contains body
                if (indexPath.item == 2) {
                    // body row
                    return [self heightForRowInTableView:tableView withBodyText:activity.body];
                } else {
                    // user/date, taxon, agree/action
                    return 44;
                }
            } else {
                // no body row, everything else 44
                return 44;
            }
        }
    }
}

- (CGFloat)heightForRowInTableView:(UITableView *)tableView withBodyText:(NSString *)text {
    // 24 for some padding on the left/right
    CGFloat usableWidth = tableView.bounds.size.width - 24;
    CGSize maxSize = CGSizeMake(usableWidth, CGFLOAT_MAX);
    UIFont *font = [UIFont systemFontOfSize:14.0f];
    
    CGRect textRect = [text boundingRectWithSize:maxSize
                                         options:NSStringDrawingUsesLineFragmentOrigin
                                      attributes:@{ NSFontAttributeName: font }
                                         context:nil];
    
    // 16 for some padding above/below
    return MAX(44, textRect.size.height + 16);
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section < 2) {
        return [super tableView:tableView viewForHeaderInSection:section];
    } else {
        UITableViewHeaderFooterView *view = [UITableViewHeaderFooterView new];
        view.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleRightMargin;
        view.frame = CGRectMake(0, 0, tableView.bounds.size.width, 30);
        [view addSubview:({
            UIView *thread = [UIView new];
            thread.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleRightMargin;
            thread.frame = CGRectMake(15 + 27 / 2.0 - 5, 0, 7, 30);
            thread.backgroundColor = [UIColor colorWithHexString:@"#d8d8d8"];
            thread;
        })];
        return view;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < 2) {
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    } else {
        if (indexPath.item == 0) {
            // each section starts with an author row
            return [self authorCellInTableView:tableView
                                  withActivity:[self activityForSection:indexPath.section]];
        } else if (indexPath.item == 1) {
            Activity *activity = [self activityForSection:indexPath.section];
            if ([activity isKindOfClass:[Comment class]]) {
                // comments follow with a body row
                return [self activityBodyCellInTableView:tableView
                                            withBodyText:activity.body];
            } else if ([activity isKindOfClass:[Identification class]]) {
                // identifications follow with a taxon row
                return [self taxonCellInTableView:tableView
                               withIdentification:(Identification *)activity];
            }
        } else if (indexPath.item == 2) {
            // must be identification
            Identification *i = (Identification *)[self activityForSection:indexPath.section];
            if (i.body && i.body.length > 0) {
                // this id has a text body
                return [self activityBodyCellInTableView:tableView
                                            withBodyText:i.body];
            } else {
                // the "more" cell for ids, currently has an agree button
                return [self moreCellInTableView:tableView
                                    withActivity:[self activityForSection:indexPath.section]];
            }
        } else if (indexPath.item == 3) {
            // the "more" cell for ids, currently has an agree button
            return [self moreCellInTableView:tableView
                                withActivity:[self activityForSection:indexPath.section]];
        } else {
            // impossibru!
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"rightDetail"];
            
            return cell;
        }
    }
}


#pragma mark - tableviewcell helpers

- (ObsDetailActivityBodyCell *)activityBodyCellInTableView:(UITableView *)tableView withBodyText:(NSString *)bodyText {
    // body
    ObsDetailActivityBodyCell *cell = [tableView dequeueReusableCellWithIdentifier:@"activityBody"];
    
    NSError *err = nil;
    cell.bodyTextView.attributedText = [[NSAttributedString alloc] initWithData:[bodyText dataUsingEncoding:NSUTF8StringEncoding]
                                                                        options:@{ NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType }
                                                             documentAttributes:nil
                                                                          error:&err];
    
    cell.bodyTextView.dataDetectorTypes = UIDataDetectorTypeLink;
    cell.bodyTextView.editable = NO;
    cell.bodyTextView.scrollEnabled = NO;
        
    return cell;
}

- (ObsDetailActivityAuthorCell *)authorCellInTableView:(UITableView *)tableView withActivity:(Activity *)activity {
    ObsDetailActivityAuthorCell *cell = [tableView dequeueReusableCellWithIdentifier:@"activityAuthor"];
    
    if (activity) {
        NSURL *userIconUrl = [NSURL URLWithString:activity.user.userIconURL];
        if (userIconUrl) {
            [cell.authorImageView sd_setImageWithURL:userIconUrl];
            cell.authorImageView.layer.cornerRadius = 27.0 / 2;
            cell.authorImageView.clipsToBounds = YES;
        }
        
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        dateFormatter.dateStyle = NSDateFormatterShortStyle;
        dateFormatter.timeStyle = NSDateFormatterNoStyle;
        dateFormatter.doesRelativeDateFormatting = YES;
        cell.dateLabel.text = [dateFormatter stringFromDate:activity.createdAt];
        cell.dateLabel.textColor = [UIColor lightGrayColor];
        
        if ([activity isKindOfClass:[Identification class]]) {
            NSString *identificationAuthor = [NSString stringWithFormat:NSLocalizedString(@"%@'s ID", @"identification author attribution"), activity.user.login];
            cell.authorNameLabel.text = identificationAuthor;
        } else {
            cell.authorNameLabel.text = activity.user.login;
        }
    }

    return cell;
}

- (ObsDetailActivityMoreCell *)moreCellInTableView:(UITableView *)tableView withActivity:(Activity *)activity {
    ObsDetailActivityMoreCell *cell = [tableView dequeueReusableCellWithIdentifier:@"activityMore"];
    
    if ([activity isKindOfClass:[Identification class]]) {
        Identification *identification = (Identification *)activity;
        
        // can't agree with your identification
        cell.agreeButton.enabled = ![self loggedInUserProducedActivity:activity];
        
        Taxon *t = [self taxonForIdentificationByLoggedInUser];
        if (t) {
            // can't agree with an identification that matches your own
            if ([t.recordID isEqual:identification.taxon.recordID]) {
                cell.agreeButton.enabled = NO;
            }
        }
        
        cell.agreeButton.tag = identification.taxon.recordID.integerValue;
    }
    
    [cell.agreeButton addTarget:self
                         action:@selector(agree:)
               forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

- (ObsDetailTaxonCell *)taxonCellInTableView:(UITableView *)tableView withIdentification:(Identification *)identification {

    ObsDetailTaxonCell *cell = [tableView dequeueReusableCellWithIdentifier:@"taxon"];
    
    Taxon *taxon = identification.taxon;
    if (taxon) {
        cell.taxonNameLabel.textColor = identification.isCurrent ? [UIColor blackColor] : [UIColor lightGrayColor];
        
        cell.taxonNameLabel.text = taxon.defaultName;
                
        if ([taxon.isIconic boolValue]) {
            cell.taxonImageView.image = [[ImageStore sharedImageStore] iconicTaxonImageForName:taxon.iconicTaxonName];
        } else if (taxon.taxonPhotos.count > 0) {
            TaxonPhoto *tp = taxon.taxonPhotos.firstObject;
            [cell.taxonImageView sd_setImageWithURL:[NSURL URLWithString:tp.thumbURL]];
        } else {
            cell.taxonImageView.image = [[ImageStore sharedImageStore] iconicTaxonImageForName:taxon.iconicTaxonName];
        }
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    return cell;
}

#pragma mark - uibutton targets

- (void)addComment {
    [self.delegate inat_performSegueWithIdentifier:@"addComment" sender:nil];
}

- (void)addIdentification {
    [self.delegate inat_performSegueWithIdentifier:@"addIdentification" sender:nil];
}

- (void)agree:(UIButton *)button {
    // add an identification
    
    [[Analytics sharedClient] debugLog:@"Network - Obs Detail Add Comment"];
    [[Analytics sharedClient] event:kAnalyticsEventObservationAddIdentification
                     withProperties:@{ @"Via": @"View Obs Agree" }];
    
    NSDictionary *params = @{
                             @"identification[observation_id]": self.observation.recordID,
                             @"identification[taxon_id]": @(button.tag),
                             };
    
    [[RKClient sharedClient] post:@"/identifications"
                           params:params
                         delegate:self];
}

- (BOOL)loggedInUserProducedActivity:(Activity *)activity {
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    LoginController *login = appDelegate.loginController;
    if (login.isLoggedIn) {
        User *loggedInUser = [login fetchMe];
        if ([loggedInUser.login isEqualToString:activity.user.login]) {
            return YES;
        }
    }
    return NO;
}

- (Taxon *)taxonForIdentificationByLoggedInUser {
    // get "my" current identification
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    LoginController *login = appDelegate.loginController;
    if (login.isLoggedIn) {
        User *loggedInUser = [login fetchMe];
        for (Identification *eachId in self.observation.identifications) {
            if ([eachId.user.login isEqualToString:loggedInUser.login] && eachId.isCurrent) {
                return eachId.taxon;
            }
        }
    }
    return nil;
}

#pragma mark - RKRequestDelegate

- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response {
    if (response.statusCode == 200) {
        [self.delegate reloadObservation];
    } else {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add Identification Failure", @"Title for add ID failed alert")
                                    message:NSLocalizedString(@"An unknown error occured. Please try again.", @"unknown error adding ID")
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"OK", nil)
                          otherButtonTitles:nil] show];
    }
}

- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error {
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add Identification Failure", @"Title for add ID failed alert")
                                message:error.localizedDescription
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"OK", nil)
                      otherButtonTitles:nil] show];
}



@end
