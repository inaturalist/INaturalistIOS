 //
//  ObsDetailActivityViewModel.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/18/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import <AFNetworking/UIImageView+AFNetworking.h>
#import <UIColor-HTMLColors/UIColor+HTMLColors.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <YLMoment/YLMoment.h>
#import <RestKit/RestKit.h>

#import "ObsDetailActivityViewModel.h"
#import "Observation.h"
#import "DisclosureCell.h"
#import "User.h"
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
#import "Analytics.h"
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

@interface ObsDetailActivityViewModel () <RKRequestDelegate> {
    BOOL hasSeenNewActivity;
}
@end

@implementation ObsDetailActivityViewModel

- (TaxaAPI *)taxaApi {
    static TaxaAPI *_api = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _api = [[TaxaAPI alloc] init];
    });
    return _api;
}

#pragma mark - uiviewcontroller lifecycle

- (void)dealloc {
    [[[RKObjectManager sharedManager] requestQueue] cancelRequestsWithDelegate:self];
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
                noInteraction = NSLocalizedString(@"Login and upload this observation to enable comments & identifications.", nil);
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
    if (indexPath.item == 1) {
        id <ActivityVisualization> activity = [self activityForSection:indexPath.section];
        if ([activity conformsToProtocol:@protocol(IdentificationVisualization)]) {
            id <IdentificationVisualization> identification = (id <IdentificationVisualization>)activity;
            RLMResults *results = [ExploreTaxonRealm objectsWhere:@"taxonId == %d", identification.taxonId];
            if (results.count == 1) {
                [self.delegate inat_performSegueWithIdentifier:@"taxon" sender:[results firstObject]];
            } else {
                __weak typeof(self) weakSelf = self;
                [self.taxaApi taxonWithId:identification.taxonId handler:^(NSArray *results, NSInteger count, NSError *error) {
                    if (results.count == 1) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [weakSelf.delegate inat_performSegueWithIdentifier:@"taxon" sender:[results firstObject]];
                            
                        });
                    }
                }];
            }
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
    
    NSError *err = nil;
    NSDictionary *opts = @{
                           NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                           NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding),
                           };
    NSMutableAttributedString *body = [[[NSAttributedString alloc] initWithData:[bodyText dataUsingEncoding:NSUTF8StringEncoding]
                                                                        options:opts
                                                             documentAttributes:nil
                                                                          error:&err] mutableCopy];
    
    // reading the text as HTML gives it a with-serif font
    [body addAttribute:NSFontAttributeName
                 value:[UIFont systemFontOfSize:14]
                 range:NSMakeRange(0, body.length)];
    
    cell.bodyTextView.attributedText = body;
    
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
        
        YLMoment *moment = [YLMoment momentWithDate:activity.createdAt];
        cell.dateLabel.text = [moment fromNowWithSuffix:NO];
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
    
    if (![identification taxonCommonName]) {
        // no common name, so only show scientific name in the main label
        cell.taxonNameLabel.text = [identification taxonScientificName];
        cell.taxonSecondaryNameLabel.text = nil;
        
        if ([identification taxonRankLevel] > 0 && [identification taxonRankLevel] <= 20) {
            cell.taxonNameLabel.font = [UIFont italicSystemFontOfSize:17];
            cell.taxonNameLabel.text = [identification taxonScientificName];
        } else {
            cell.taxonNameLabel.font = [UIFont systemFontOfSize:17];
            cell.taxonNameLabel.text = [NSString stringWithFormat:@"%@ %@",
                                        [[identification taxonRank] capitalizedString],
                                        [identification taxonScientificName]];
        }
    } else {
        // show both common & scientfic names
        cell.taxonNameLabel.text = [identification taxonCommonName];
        cell.taxonNameLabel.font = [UIFont systemFontOfSize:17];
        
        if ([identification taxonRankLevel] > 0 && [identification taxonRankLevel] <= 20) {
            cell.taxonSecondaryNameLabel.font = [UIFont italicSystemFontOfSize:14];
            cell.taxonSecondaryNameLabel.text = [identification taxonScientificName];
        } else {
            cell.taxonSecondaryNameLabel.font = [UIFont systemFontOfSize:14];
            cell.taxonSecondaryNameLabel.text = [NSString stringWithFormat:@"%@ %@",
                                                 [[identification taxonRank] capitalizedString],
                                                 [identification taxonScientificName]];
            
        }
    }
    
    if (![identification isCurrent]) {
        NSDictionary *attrs = @{
                                NSStrikethroughStyleAttributeName: @(NSUnderlineStyleSingle)
                                };
        
        
        NSAttributedString* attrText = [[NSAttributedString alloc] initWithString:cell.taxonNameLabel.text
                                                                       attributes:attrs];
        cell.taxonNameLabel.attributedText = attrText;
        
        if (cell.taxonSecondaryNameLabel.text) {
            attrText = [[NSAttributedString alloc] initWithString:cell.taxonSecondaryNameLabel.text
                                                       attributes:attrs];
            cell.taxonSecondaryNameLabel.attributedText = attrText;
        }
    }
    
    
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
                               message:NSLocalizedString(@"Network is required.", @"Network is required error message")];
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
                               message:NSLocalizedString(@"Network is required.", @"Network is required error message")];
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
        [self.delegate noticeWithTitle:NSLocalizedString(@"Couldn't Agree", nil)
                               message:NSLocalizedString(@"Network is required.", @"Network is required error message")];
        return;
    }
    
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    if (!appDelegate.loginController.isLoggedIn) {
        [self.delegate noticeWithTitle:NSLocalizedString(@"Couldn't Agree", nil)
                               message:NSLocalizedString(@"You must be logged in.", @"Account is required error message")];
        return;
    }
    
    // add an identification
    [[Analytics sharedClient] event:kAnalyticsEventObservationAddIdentification
                     withProperties:@{ @"Via": @"View Obs Agree" }];
        
    [self.delegate showProgressHud];
    
    __weak typeof(self)weakSelf = self;
    IdentificationsAPI *api = [[IdentificationsAPI alloc] init];
    [api addIdentificationTaxonId:button.tag observationId:self.observation.inatRecordId body:nil vision:NO handler:^(NSArray *results, NSInteger count, NSError *error) {
        [weakSelf.delegate hideProgressHud];
        if (error) {
            [self.delegate noticeWithTitle:NSLocalizedString(@"Add Identification Failure", @"Title for add ID failed alert")
                                   message:error.localizedDescription];
        } else {
            [weakSelf.delegate reloadObservation];
        }
    }];
}

#pragma mark - misc helpers

- (void)markActivityAsSeen {
    if (self.observation.inatRecordId && self.observation.hasUnviewedActivityBool && [self.observation isKindOfClass:[Observation class]]) {
        Observation *obs = (Observation *)self.observation;
        obs.hasUnviewedActivity = [NSNumber numberWithBool:NO];
        NSError *error = nil;
        [[[RKObjectManager sharedManager] objectStore] save:&error];

        ObservationAPI *api = [[ObservationAPI alloc] init];
        // the API won't take a nil callback at this point
        [api seenUpdatesForObservationId:self.observation.inatRecordId handler:^(NSArray *results, NSInteger count, NSError *error) { }];
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"resourceId == %ld", [self.observation inatRecordId]];
    RLMResults *results = [ExploreUpdateRealm objectsWithPredicate:predicate];
    [[RLMRealm defaultRealm] transactionWithBlock:^{
        [results setValue:@(YES) forKey:@"viewed"];
        [results setValue:@(YES) forKey:@"viewedLocally"];
    }];
    [self.delegate setUpdatesBadge];
}

- (BOOL)loggedInUserProducedActivity:(id <ActivityVisualization>)activity {
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    LoginController *login = appDelegate.loginController;
    if (login.isLoggedIn) {
        User *loggedInUser = [login fetchMe];
        if ([loggedInUser.login isEqualToString:[activity userName]]) {
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
        User *loggedInUser = [login fetchMe];
        for (id <IdentificationVisualization> eachId in self.observation.identifications) {
            if ([[eachId userName] isEqualToString:loggedInUser.login] && [eachId isCurrent]) {
                
                NSPredicate *taxonPredicate = [NSPredicate predicateWithFormat:@"recordID == %ld", [eachId taxonId]];
                Taxon *taxon = [[Taxon objectsWithPredicate:taxonPredicate] firstObject];
                
                return [[taxon recordID] integerValue];
            }
        }
    }
    return 0;

}

#pragma mark - RKRequestDelegate

- (void)request:(RKRequest *)request didLoadResponse:(RKResponse *)response {
    
    [self.delegate hideProgressHud];
    
    
    if (request.method ==RKRequestMethodGET) {
        return;
    }
    
    // set "seen" call returns 204 on success, add ID returns 200
    if (response.statusCode == 200 || response.statusCode == 204) {
        if ([response.URL.absoluteString rangeOfString:@"/identifications"].location != NSNotFound) {
            // reload the observation after the user has agreed (thus made a new ID)
            [self.delegate reloadObservation];
        }
    } else {
        if ([response.URL.absoluteString rangeOfString:@"/identifications"].location != NSNotFound) {
            // identification
            [self.delegate noticeWithTitle:NSLocalizedString(@"Add Identification Failure", @"Title for add ID failed alert")
                                   message:NSLocalizedString(@"An unknown error occured. Please try again.", @"unknown error adding content")];
        } else {
            // comment
            [self.delegate noticeWithTitle:NSLocalizedString(@"Add Comment Failure", @"Title for add comment failed alert")
                                   message:NSLocalizedString(@"An unknown error occured. Please try again.", @"unknown error adding content")];
        }
    }
}

- (void)request:(RKRequest *)request didFailLoadWithError:(NSError *)error {
    [self.delegate hideProgressHud];
    
    if ([request.URL.absoluteString rangeOfString:@"/identifications"].location != NSNotFound) {
        [self.delegate noticeWithTitle:NSLocalizedString(@"Add Identification Failure", @"Title for add ID failed alert")
                               message:error.localizedDescription];
    } else {
        [self.delegate noticeWithTitle:NSLocalizedString(@"Add Comment Failure", @"Title for add comment failed alert")
                               message:error.localizedDescription];
    }
}



@end
