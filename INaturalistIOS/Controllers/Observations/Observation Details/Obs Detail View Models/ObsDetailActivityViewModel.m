 //
//  ObsDetailActivityViewModel.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/18/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

@import AFNetworking;
@import UIColor_HTMLColors;
@import MBProgressHUD;

#import "ObsDetailActivityViewModel.h"
#import "Observation.h"
#import "DisclosureCell.h"
#import "Taxon.h"
#import "ExploreTaxon.h"
#import "ExploreTaxonRealm.h"
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
#import "ObsDetailNoInteractionHeaderFooter.h"
#import "IdentificationVisualization.h"
#import "CommentVisualization.h"
#import "ActivityVisualization.h"
#import "ExploreComment.h"
#import "UIImage+INaturalist.h"
#import "TaxaAPI.h"
#import "ExploreUpdateRealm.h"
#import "INatReachability.h"
#import "IdentificationsAPI.h"
#import "ObservationAPI.h"
#import "iNaturalist-Swift.h"
#import "NSDate+INaturalist.h"


@interface ObsDetailActivityViewModel () {
    BOOL hasSeenNewActivity;
}
@end

@implementation ObsDetailActivityViewModel

- (IdentificationsAPI *)identificationsApi {
    static IdentificationsAPI *_api = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _api = [[IdentificationsAPI alloc] init];
    });
    return _api;
}

- (TaxaAPI *)taxaApi {
    static TaxaAPI *_api = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _api = [[TaxaAPI alloc] init];
    });
    return _api;
}

- (ObservationAPI *)observationApi {
    static ObservationAPI *_api = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _api = [[ObservationAPI alloc] init];
    });
    return _api;
}

#pragma mark - uitableview datasource/delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section < 2) {
        return [super tableView:tableView numberOfRowsInSection:section];
    } else {
        if (self.observation.sortedActivity.count == 0) {
            // if activity hasn't been loaded from the server yet
            return 0;
        }
        id <ActivityVisualization> activity = [self activityForSection:section];
        if ([activity hidden]) {
            return 1;
        }

        if ([activity conformsToProtocol:@protocol(CommentVisualization)]) {
            return 2;
        } else if ([activity conformsToProtocol:@protocol(IdentificationVisualization)]) {
            id <IdentificationVisualization> identification = (id <IdentificationVisualization>)activity;
            
            NSInteger baseRows = 3;
            
            NSInteger myTaxonId = [self taxonIdForIdentificationByLoggedInUser];
            // can't agree with my ID, can't agree with an ID that matches my own
            if ([self loggedInUserProducedActivity:activity] || (myTaxonId == [identification taxonId])) {
                // can't agree with your own identification
                // so don't show row with agree button
                baseRows--;
            }
            
            if (identification.body && identification.body.length > 0) {
                baseRows++;
            }
            
            return baseRows;
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
        if (self.observation.inatRecordId) {
            ObsDetailAddActivityFooter *footer = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"addActivityFooter"];
            [footer.commentButton addTarget:self
                                     action:@selector(addComment)
                           forControlEvents:UIControlEventTouchUpInside];
            [footer.suggestIDButton addTarget:self
                                       action:@selector(addIdentification)
                             forControlEvents:UIControlEventTouchUpInside];
            return footer;
        } else {
            NSString *noInteraction;
            
            INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
            if (appDelegate.loginController.isLoggedIn) {
                noInteraction = NSLocalizedString(@"Upload this observation to enable comments & identifications.", nil);
            } else {
                noInteraction = NSLocalizedString(@"Log in and upload this observation to enable comments & identifications.", nil);
            }
            
            ObsDetailNoInteractionHeaderFooter *footer = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"noInteraction"];
            footer.noInteractionLabel.text = noInteraction;
            return footer;
        }
    } else {
        return nil;
    }
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
        id <ActivityVisualization> activity = [self activityForSection:indexPath.section];
        if ([activity hidden]) {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"rightDetail"];

            NSString *hiddenMsg = NSLocalizedString(@"Content Hidden", "when content has been moderated");

            if (@available(iOS 13.0, *)) {
                NSTextAttachment *textAttachment = [[NSTextAttachment alloc] init];
                textAttachment.image = [UIImage systemImageNamed:@"eye.slash"];
                NSMutableAttributedString *labelTxt = [[NSMutableAttributedString alloc] init];
                [labelTxt appendAttributedString:[NSAttributedString attributedStringWithAttachment:textAttachment]];
                [labelTxt appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];

                [labelTxt appendAttributedString:[[NSAttributedString alloc] initWithString:hiddenMsg]];

                cell.textLabel.attributedText = labelTxt;

            } else {
                cell.textLabel.text = hiddenMsg;
            }


            return cell;
        }

        if (indexPath.item == 0) {
            // each section starts with an author row
            return [self authorCellInTableView:tableView
                                  withActivity:[self activityForSection:indexPath.section]];
        } else if (indexPath.item == 1) {
            id <ActivityVisualization> activity = [self activityForSection:indexPath.section];
            if ([activity conformsToProtocol:@protocol(CommentVisualization)]) {
                // comments follow with a body row
                return [self activityBodyCellInTableView:tableView
                                            withBodyText:activity.body];
            } else if ([activity conformsToProtocol:@protocol(IdentificationVisualization)]) {
                // identifications follow with a taxon row
                return [self taxonCellInTableView:tableView
                               withIdentification:(id <IdentificationVisualization>)activity];
            }
        } else if (indexPath.item == 2) {
            // must be identification
            id <IdentificationVisualization> i = (id <IdentificationVisualization>)[self activityForSection:indexPath.section];
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
    
    // avoid the warning
    return [UITableViewCell new];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == [tableView numberOfSections] - 1) {
        if (!hasSeenNewActivity) {
            [self markActivityAsSeen];
            hasSeenNewActivity = YES;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < 2) {
        [super tableView:tableView didSelectRowAtIndexPath:indexPath];
        return;
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    // second row in an identification section is a taxon row, which is selectable
    id activity = [self activityForSection:indexPath.section];
    if ([activity hidden]) {
        NSDateFormatter *df = [[NSDateFormatter alloc] init];
        df.timeStyle = NSDateFormatterNoStyle;
        df.dateStyle = NSDateFormatterMediumStyle;

        NSString *alertBodyBaseText = NSLocalizedString(@"Content hidden by %@ on %@ because: '%@'", 
                                                        @"explanation for why a users content was moderated & hidden. First string is the moderator login, second is the date, third is the reason for the moderation.");
        NSString *alertBody = [NSString stringWithFormat:alertBodyBaseText,
                               [activity moderatorUsername], 
                               [df stringFromDate:[activity moderationDate]],
                               [activity moderationReason]];
        NSString *alertTitle = NSLocalizedString(@"Content Hidden", @"Title for content hidden reason alert.");
                
        BOOL contactSupportOption = NO;
        INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];

        // only show the contact support option for users if it was their activity that was moderated
        if (appDelegate.loginController.isLoggedIn && appDelegate.loginController.meUserId == [activity userId]) {
            contactSupportOption = YES;
        }

        [self.delegate noticeWithTitle:alertTitle message:alertBody contactSupportOption:contactSupportOption];
    }

    if (indexPath.item == 1) {
        id <ActivityVisualization> activity = [self activityForSection:indexPath.section];
        if ([activity conformsToProtocol:@protocol(IdentificationVisualization)]) {
            id <IdentificationVisualization> identification = (id <IdentificationVisualization>)activity;
            [self.delegate inat_performSegueWithIdentifier:@"taxon" sender:@(identification.taxonId)];
        }
    }
}

#pragma mark - section helpers

- (id <ActivityVisualization>)activityForSection:(NSInteger)section {
    id activity = nil;
    
    @try {
        // first 2 sections are for observation metadata
        activity = self.observation.sortedActivity[section - 2];
    } @catch (NSException *exception) {
        if (exception.name == NSRangeException) {
            // if the observation is being reloaded, sortedActivity might be empty
            // do nothing
        } else {
            @throw;
        }
    } @finally {
        return activity;
    }
}

- (ObsDetailSection)sectionType {
    return ObsDetailSectionActivity;
}

#pragma mark - tableviewcell helpers

- (ObsDetailActivityBodyCell *)activityBodyCellInTableView:(UITableView *)tableView withBodyText:(NSString *)bodyText {
    // body
    ObsDetailActivityBodyCell *cell = [tableView dequeueReusableCellWithIdentifier:@"activityBody"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"bootstrap" ofType:@"min.css"];
    NSError *error = nil;
    NSString *css = [NSString stringWithContentsOfFile:path
                                              encoding:NSUTF8StringEncoding
                                                 error:&error];
    DownWrapper *dw = [[DownWrapper alloc] init];
    NSAttributedString *attrStr = [dw markdownToAttributedStringWithMarkdownStr:bodyText
                                                                            css:css];
    cell.bodyTextView.attributedText = attrStr;
    
    cell.bodyTextView.dataDetectorTypes = UIDataDetectorTypeLink;
    cell.bodyTextView.editable = NO;
    cell.bodyTextView.scrollEnabled = NO;
    
    return cell;
}

- (ObsDetailActivityAuthorCell *)authorCellInTableView:(UITableView *)tableView withActivity:(id <ActivityVisualization>)activity {
    ObsDetailActivityAuthorCell *cell = [tableView dequeueReusableCellWithIdentifier:@"activityAuthor"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    if (activity) {
        NSURL *userIconUrl = [activity userIconUrl];
        if (userIconUrl) {
            [cell.authorImageView setImageWithURL:userIconUrl
                                 placeholderImage:[UIImage inat_defaultUserImage]];
            cell.authorImageView.layer.cornerRadius = 27.0 / 2;
            cell.authorImageView.clipsToBounds = YES;
        } else {
            cell.authorImageView.image = [UIImage inat_defaultUserImage];
        }

        if (self.observation.trueCoordinateVisibility == ObsTrueCoordinatePrivacyVisible) {
            cell.dateLabel.text = [activity.createdAt inat_shortRelativeDateString];
        } else {
            cell.dateLabel.text = [activity.createdAt inat_obscuredDateString];
        }

        cell.dateLabel.textColor = [UIColor lightGrayColor];
        
        if ([activity conformsToProtocol:@protocol(IdentificationVisualization)]) {
            // TODO: push this down into protocol implementation
            id <IdentificationVisualization> identification = (id <IdentificationVisualization>)activity;
            NSString *identificationAuthor = [NSString stringWithFormat:NSLocalizedString(@"%@'s ID", @"identification author attribution"), [identification userName]];
            cell.authorNameLabel.text = identificationAuthor;
        } else {
            cell.authorNameLabel.text = [activity userName];
        }
    }
    
    return cell;
}

- (ObsDetailActivityMoreCell *)moreCellInTableView:(UITableView *)tableView withActivity:(id <ActivityVisualization>)activity {
    ObsDetailActivityMoreCell *cell = [tableView dequeueReusableCellWithIdentifier:@"activityMore"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    
    if ([activity conformsToProtocol:@protocol(IdentificationVisualization)]) {
        // TODO: push this down into protocol implementation
        id <IdentificationVisualization> identification = (id <IdentificationVisualization>)activity;
        
        // can't agree with your identification
        cell.agreeButton.enabled = ![self loggedInUserProducedActivity:activity];
        
        NSInteger myTaxonId = [self taxonIdForIdentificationByLoggedInUser];
        if (myTaxonId != 0) {
            // can't agree with an identification that matches your own
            if (myTaxonId == [identification taxonId]) {
                cell.agreeButton.enabled = NO;
            }
        }
        
        cell.agreeButton.tag = [identification taxonId];
    }
    
    [cell.agreeButton addTarget:self
                         action:@selector(agree:)
               forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

- (ObsDetailTaxonCell *)taxonCellInTableView:(UITableView *)tableView withIdentification:(id <IdentificationVisualization>)identification {
    
    ObsDetailTaxonCell *cell = [tableView dequeueReusableCellWithIdentifier:@"taxonFromNib"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    cell.taxonNameLabel.text = [[identification taxon] displayFirstName];
    if ([[identification taxon] displayFirstNameIsItalicized]) {
        cell.taxonNameLabel.font = [UIFont italicSystemFontOfSize:17];
    } else {
        cell.taxonNameLabel.font = [UIFont systemFontOfSize:17];
    }
    
    cell.taxonSecondaryNameLabel.text = [[identification taxon] displaySecondName];
    if ([[identification taxon] displaySecondNameIsItalicized]) {
        cell.taxonSecondaryNameLabel.font = [UIFont italicSystemFontOfSize:14];
    } else {
        cell.taxonSecondaryNameLabel.font = [UIFont systemFontOfSize:14];
    }
    
    // upon cell re-use, these attrs aren't always cleared :(
    // so we explicitly set the strikethrough to none or single
    // line every dequeue :/
    NSDictionary *attrs = @{
        NSStrikethroughStyleAttributeName: @(NSUnderlineStyleNone)
    };
    if (![identification isCurrent]) {
        attrs = @{
            NSStrikethroughStyleAttributeName: @(NSUnderlineStyleSingle)
        };
    }
    
    // do the primary name label
    NSAttributedString* attrText = [[NSAttributedString alloc] initWithString:cell.taxonNameLabel.text
                                                                   attributes:attrs];
    cell.taxonNameLabel.attributedText = attrText;
    
    // if necessary, do the secondary name label, too
    if (cell.taxonSecondaryNameLabel.text) {
        attrText = [[NSAttributedString alloc] initWithString:cell.taxonSecondaryNameLabel.text
                                                   attributes:attrs];
        cell.taxonSecondaryNameLabel.attributedText = attrText;
    }
    
    // cancel any existing download task
    [cell.taxonImageView cancelImageDownloadTask];
    cell.taxonImageView.image = nil;
    
    if ([identification taxonIconUrl]) {
        [cell.taxonImageView setImageWithURL:[identification taxonIconUrl]];
    } else {
        cell.taxonImageView.image = [[ImageStore sharedImageStore] iconicTaxonImageForName:[identification taxonIconicName]];
    }
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

#pragma mark - uibutton targets

- (void)addComment {
    if (![[INatReachability sharedClient] isNetworkReachable]) {
        [self.delegate noticeWithTitle:NSLocalizedString(@"Can't Comment", nil)
                               message:NSLocalizedString(@"Network is required.", @"Network (i.e. an Internet connection) is required error message")];
        return;
    }
    
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (!appDelegate.loginController.isLoggedIn) {
        [self.delegate noticeWithTitle:NSLocalizedString(@"Can't Comment", nil)
                               message:NSLocalizedString(@"You must be logged in.", @"Account is required error message")];
        return;
    }
    
    [self.delegate inat_performSegueWithIdentifier:@"addComment" sender:nil];
}

- (void)addIdentification {
    if (![[INatReachability sharedClient] isNetworkReachable]) {
        [self.delegate noticeWithTitle:NSLocalizedString(@"Can't Add ID", nil)
                               message:NSLocalizedString(@"Network is required.", @"Network (i.e. an Internet connection) is required error message")];
        return;
    }
    
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (!appDelegate.loginController.isLoggedIn) {
        [self.delegate noticeWithTitle:NSLocalizedString(@"Can't Add ID", nil)
                               message:NSLocalizedString(@"You must be logged in.", @"Account is required error message")];
        return;
    }
    
    [self.delegate inat_performSegueWithIdentifier:@"addIdentification" sender:nil];
}

- (void)agree:(UIButton *)button {
    if (![[INatReachability sharedClient] isNetworkReachable]) {
        [self.delegate noticeWithTitle:NSLocalizedString(@"Couldn't Agree", @"Title of an alert dialog you see when you try to agree with an identification but cannot due to connection issues or other errors")
                               message:NSLocalizedString(@"Network is required.", @"Network (i.e. an Internet connection) is required error message")];
        return;
    }
    
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (!appDelegate.loginController.isLoggedIn) {
        [self.delegate noticeWithTitle:NSLocalizedString(@"Couldn't Agree", @"Title of an alert dialog you see when you try to agree with an identification but cannot due to connection issues or other errors")
                               message:NSLocalizedString(@"You must be logged in.", @"Account is required error message")];
        return;
    }
            
    [self.delegate showProgressHud];
    
    __weak typeof(self)weakSelf = self;
    [[self identificationsApi] addIdentificationTaxonId:button.tag
                                          observationId:self.observation.inatRecordId
                                                   body:nil
                                                 vision:NO
                                                handler:^(NSArray *results, NSInteger count, NSError *error) {
        
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.delegate hideProgressHud];
        if (error) {
            [strongSelf.delegate noticeWithTitle:NSLocalizedString(@"Add Identification Failure", @"Title for add ID failed alert")
                                         message:error.localizedDescription];
        } else {
            [strongSelf.delegate reloadObservation];
        }
    }];
}

#pragma mark - misc helpers

- (void)markActivityAsSeen {

    if (self.observation.hasUnviewedActivityBool) {
        
        // clear local unseen status right away
        RLMResults *updates = [ExploreUpdateRealm updatesForObservationId:self.observation.inatRecordId];

        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm beginWriteTransaction];
        [updates setValue:@(YES) forKey:@"viewed"];
        [updates setValue:@(YES) forKey:@"viewedLocally"];
        [realm commitWriteTransaction];
        
        [self.delegate reloadTableView];
        
        // notify the server that we've seen the updates for this observation
        [[self observationApi] seenUpdatesForObservationId:self.observation.inatRecordId
                                                   handler:^(NSArray *results, NSInteger count, NSError *error) { }];
    }
}

- (BOOL)loggedInUserProducedActivity:(id <ActivityVisualization>)activity {
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    LoginController *login = appDelegate.loginController;
    if (login.isLoggedIn) {
        ExploreUserRealm *me = [login meUserLocal];
        if ([me.login isEqualToString:[activity userName]]) {
            return YES;
        }
    }
    return NO;
}

- (NSInteger)taxonIdForIdentificationByLoggedInUser {
    // get "my" current identification
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    LoginController *login = appDelegate.loginController;
    if (login.isLoggedIn) {
        ExploreUserRealm *loggedInUser = [login meUserLocal];
        for (id <IdentificationVisualization> id in self.observation.identifications) {
            if ([id userId] == loggedInUser.userId && [id isCurrent]) {
                return id.taxonId;
            }
        }
    }
    return 0;

}

@end
