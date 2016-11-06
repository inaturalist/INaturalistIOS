//
//  UpdatesViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 10/21/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>
#import <YLMoment/YLMoment.h>
#import <SVPullToRefresh/SVPullToRefresh.h>

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
@end

@implementation UpdatesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.tableFooterView = [UIView new];
    
    __weak typeof(self) weakSelf = self;
    [self.tableView addPullToRefreshWithActionHandler:^{
        [weakSelf loadUpdates];
    }];
    
    [self loadUpdates];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.tableView reloadData];
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
    INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
    User *me = [appDelegate.loginController fetchMe];
    NSPredicate *myUpdates = [NSPredicate predicateWithFormat:@"resourceOwnerId == %ld", me.recordID.integerValue];
    self.updates = [[ExploreUpdateRealm objectsWithPredicate:myUpdates]
                    sortedResultsUsingProperty:@"createdAt" ascending:NO];
    
    [appDelegate.loginController getJWTTokenSuccess:^(NSDictionary *info) {
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
                    [self.tableView reloadData];
                    [self.tableView.pullToRefreshView stopAnimating];
                    [self.tableView.infiniteScrollingView stopAnimating];
                    
                    [(INatUITabBarController *)self.tabBarController setUpdatesBadge];
                });
            }

        }];
    } failure:^(NSError *error) {
        return;
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
    return 1;
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
            [tableView reloadRowsAtIndexPaths:@[ indexPath ]
                             withRowAnimation:UITableViewRowAnimationFade];
        }];
    }
    if (o.observationPhotos.count > 0) {
        ObservationPhoto *op = [o.sortedObservationPhotos firstObject];
        [cell.observationImageView sd_setImageWithURL:op.squarePhotoUrl];
    } else {
        NSString *iconicTaxonName = o.iconicTaxonName;
        cell.observationImageView.image = [UIImage imageForIconicTaxon:iconicTaxonName];
    }
    
    YLMoment *moment = [YLMoment momentWithDate:eur.createdAt];
    cell.updateDateTextLabel.text = [moment fromNowWithSuffix:NO];
    
    if (!eur.viewed) {
        cell.backgroundColor = [[UIColor inatTint] colorWithAlphaComponent:0.1f];
    }
    
    if (eur.identification) {
        if (eur.identification.identifier.userIcon) {
            [cell.profileImageView sd_setImageWithURL:eur.identification.identifier.userIcon];
        } else {
            cell.profileImageView.image = [UIImage inat_defaultUserImage];
        }
        
        cell.updateTextLabel.text = [NSString stringWithFormat:@"%@ suggested an ID: %@",
                                     eur.identification.identifier.login,
                                     eur.identification.taxon.commonName ?: eur.identification.taxon.scientificName
                                     ];
    } else if (eur.comment) {
        if (eur.comment.commenter.userIcon) {
            [cell.profileImageView sd_setImageWithURL:eur.comment.commenter.userIcon];
        } else {
            cell.profileImageView.image = [UIImage inat_defaultUserImage];
        }

        cell.updateTextLabel.text = [NSString stringWithFormat:@"%@ commented: %@",
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
        
        NSPredicate *obsPredicate = [NSPredicate predicateWithFormat:@"recordID == %d", eur.resourceId];
        Observation *o = [Observation objectWithPredicate:obsPredicate];
        vc.observation = o;
        
        [[Analytics sharedClient] event:kAnalyticsEventNavigateObservationDetail
                         withProperties:@{ @"via": @"Updates" }];
    }
}

@end
