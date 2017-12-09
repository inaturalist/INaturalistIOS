//
//  UpdatesViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 10/21/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <AFNetworking/UIImageView+AFNetworking.h>
#import <YLMoment/YLMoment.h>
#import <SVPullToRefresh/SVPullToRefresh.h>
#import <UIColor-HTMLColors/UIColor+HTMLColors.h>
#import <RestKit/RestKit.h>

#import "ExploreUpdateRealm.h"
#import "UpdatesViewController.h"
#import "INaturalistAppDelegate.h"
#import "LoginController.h"
#import "ObservationAPI.h"
#import "Analytics.h"
#import "User.h"
#import "Observation.h"
#import "UpdatesItemCell.h"
#import "ObservationPhoto.h"
#import "UIImage+ExploreIconicTaxaImages.h"
#import "UIImage+INaturalist.h"
#import "ObsDetailV2ViewController.h"
#import "UIColor+INaturalist.h"
#import "INatUITabBarController.h"

@interface UpdatesViewController ()
@property RLMResults *updates;
@property RLMNotificationToken *updatesToken;
@end

@implementation UpdatesViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(userLoggedIn)
                                                     name:kINatLoggedInNotificationKey
                                                   object:nil];
    }
    
    return self;
}

- (void)dealloc {
    [self.updatesToken stop];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)userLoggedIn {
    [self loadUpdates];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.tableFooterView = [UIView new];
    
    __weak typeof(self) weakSelf = self;
    [self.tableView addPullToRefreshWithActionHandler:^{
        [weakSelf loadUpdates];
    }];
    
    self.tableView.backgroundView = ({
        UILabel *label = [UILabel new];
        label.numberOfLines = 0;
        label.textAlignment = NSTextAlignmentCenter;
        
        label.attributedText = ({
            NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] init];
            [attr appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"No updates yet. Stay tuned!", nil)
                                                                         attributes:@{
                                                                                      NSFontAttributeName: [UIFont systemFontOfSize:17.0f],
                                                                                      NSForegroundColorAttributeName: [UIColor colorWithHexString:@"#505050"],
                                                                                      }]];
            [attr appendAttributedString:[[NSAttributedString alloc] initWithString:@"\n\n"]];
            [attr appendAttributedString:[[NSAttributedString alloc] initWithString:NSLocalizedString(@"You will receive updates once you've uploaded observations.", nil)
                                                                        attributes:@{
                                                                                     NSFontAttributeName: [UIFont systemFontOfSize:14.0f],
                                                                                     NSForegroundColorAttributeName: [UIColor colorWithHexString:@"#8F8E94"],
                                                                                     }]];
            
            attr;
        });

        label;
    });

    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    User *me = [appDelegate.loginController fetchMe];
    NSPredicate *myUpdates = [NSPredicate predicateWithFormat:@"resourceOwnerId == %ld", me.recordID.integerValue];
    self.updates = [[ExploreUpdateRealm objectsWithPredicate:myUpdates]
                    sortedResultsUsingProperty:@"createdAt" ascending:NO];
    
    self.updatesToken = [self.updates addNotificationBlock:^(RLMResults * _Nullable results, RLMCollectionChange * _Nullable change, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.tableView reloadData];
        });
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.tableView reloadData];
    
    [self markSeenObservations];
}

- (void)markSeenObservations {
    // stash the new IDs so we can notify the server that it's been seen
    NSMutableSet *obsIds = [NSMutableSet set];
    for (ExploreUpdateRealm *new in [self.updates objectsWhere:@"viewed == NO"]) {
        [obsIds addObject:@(new.resourceId)];
    }
    
    // clear flag on all updates
    [[RLMRealm defaultRealm] transactionWithBlock:^{
        [self.updates setValue:@(YES) forKey:@"viewed"];
    }];
    
    // set application and tab bar badge
    [((INatUITabBarController *)self.tabBarController) setUpdatesBadge];
    
    for (NSNumber *obsId in obsIds) {
        [[self observationApi] seenUpdatesForObservationId:obsId.integerValue handler:^(NSArray *results, NSInteger count, NSError *error) {
            // update hasUnviewedActivity flag
            NSPredicate *obsPredicate = [NSPredicate predicateWithFormat:@"recordID == %@", obsId];
            Observation *obs = [[Observation objectsWithPredicate:obsPredicate] firstObject];
            if (obs) {
                obs.hasUnviewedActivity = [NSNumber numberWithBool:NO];
                NSError *error = nil;
                [[[RKObjectManager sharedManager] objectStore] save:&error];
            }
        }];
    }
}

- (ObservationAPI *)observationApi {
    static ObservationAPI *_api = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _api = [[ObservationAPI alloc] init];
    });
    return _api;
}

- (void)loadUpdates {
    if (self.viewIfLoaded) {
        [self.tableView.pullToRefreshView startAnimating];
    }

    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    [self.observationApi updatesWithHandler:^(NSArray *results, NSInteger count, NSError *error) {
        
        if (error) {
            return;
        }
        
        RLMRealm *realm = [RLMRealm defaultRealm];
        [realm beginWriteTransaction];
        for (ExploreUpdate *eu in results) {
            ExploreUpdateRealm *eur = [[ExploreUpdateRealm alloc] initWithMantleModel:eu];
            [realm addOrUpdateObject:eur];
        }
        [realm commitWriteTransaction];
        
        if (self.viewIfLoaded) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self markSeenObservations];
                [self.tableView.pullToRefreshView stopAnimating];
                [(INatUITabBarController *)self.tabBarController setUpdatesBadge];
            });
        }
        
    }];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ExploreUpdateRealm *eur = [self.updates objectAtIndex:indexPath.item];
    [self performSegueWithIdentifier:@"obsDetail" sender:eur];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (self.updates.count > 0) {
        tableView.backgroundView.hidden = YES;
        return 1;
    } else {
        tableView.backgroundView.hidden = NO;
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.updates.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UpdatesItemCell *cell = [tableView dequeueReusableCellWithIdentifier:@"updateCell" forIndexPath:indexPath];
    
    ExploreUpdateRealm *eur = [self.updates objectAtIndex:indexPath.item];
    
    NSPredicate *obsPredicate = [NSPredicate predicateWithFormat:@"recordID == %d", eur.resourceId];
    Observation *o = [Observation objectWithPredicate:obsPredicate];
    if (!o) {
        // fetch this observation, reload the cell
        [[self observationApi] railsObservationWithId:eur.resourceId handler:^(NSArray *results, NSInteger count, NSError *error) {
            if (error) {
                // just get rid of this update
                RLMRealm *realm = [RLMRealm defaultRealm];
                [realm beginWriteTransaction];
                [realm deleteObjects:@[ eur ]];
                [realm commitWriteTransaction];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [tableView reloadRowsAtIndexPaths:@[ indexPath ]
                                     withRowAnimation:UITableViewRowAnimationFade];
                });
            }
        }];
    }
    if (o.observationPhotos.count > 0) {
        ObservationPhoto *op = [o.sortedObservationPhotos firstObject];
        [cell.observationImageView setImageWithURL:op.squarePhotoUrl];
    } else {
        NSString *iconicTaxonName = o.iconicTaxonName;
        cell.observationImageView.image = [UIImage imageForIconicTaxon:iconicTaxonName];
    }
    
    YLMoment *moment = [YLMoment momentWithDate:eur.createdAt];
    cell.updateDateTextLabel.text = [moment fromNowWithSuffix:NO];
    
    if (!eur.viewedLocally) {
        cell.backgroundColor = [[UIColor inatTint] colorWithAlphaComponent:0.1f];
    }
    
    if (eur.identification) {
        if (eur.identification.identifier.userIcon) {
            [cell.profileImageView setImageWithURL:eur.identification.identifier.userIcon];
        } else {
            cell.profileImageView.image = [UIImage inat_defaultUserImage];
        }
        NSString *base = NSLocalizedString(@"%1$@ suggested an ID: %2$@",
                                           @"update notice when someone suggests an ID. %1$@ is the username, %2$@ is the species.");
        cell.updateTextLabel.text = [NSString stringWithFormat:base,
                                     eur.identification.identifier.login,
                                     eur.identification.taxon.commonName ?: eur.identification.taxon.scientificName
                                     ];
    } else if (eur.comment) {
        if (eur.comment.commenter.userIcon) {
            [cell.profileImageView setImageWithURL:eur.comment.commenter.userIcon];
        } else {
            cell.profileImageView.image = [UIImage inat_defaultUserImage];
        }

        NSString *base = NSLocalizedString(@"%1$@ commented: %2$@",
                                           @"update notice when someone comments. %1$@ is the commenter name, %2$@ is the comment.");
        cell.updateTextLabel.text = [NSString stringWithFormat:base,
                                     eur.comment.commenter.login,
                                     eur.comment.commentText
                                     ];
    }
    
    return cell;
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"obsDetail"]) {
        ExploreUpdateRealm *eur = (ExploreUpdateRealm *)sender;
        
        ObsDetailV2ViewController *vc = (ObsDetailV2ViewController *)segue.destinationViewController;
        vc.shouldShowActivityOnLoad = YES;
        
        NSPredicate *obsPredicate = [NSPredicate predicateWithFormat:@"recordID == %d", eur.resourceId];
        Observation *o = [Observation objectWithPredicate:obsPredicate];
        if (o) {
            vc.observation = o;
        } else {
            vc.observationId = eur.resourceId;
        }
    
        [[Analytics sharedClient] event:kAnalyticsEventNavigateObservationDetail
                         withProperties:@{ @"via": @"Updates" }];
    }
}

@end
