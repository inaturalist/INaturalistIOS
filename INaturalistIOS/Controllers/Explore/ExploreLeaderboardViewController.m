//
//  ExploreLeaderboardViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/17/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <AFNetworking/UIImageView+AFNetworking.h>
#import <BlocksKit/BlocksKit.h>

#import "ExploreLeaderboardViewController.h"
#import "ExploreObservationsController.h"
#import "ExploreLeaderboardCell.h"
#import "ExploreLeaderboardHeader.h"
#import "Taxon.h"
#import "ExploreUser.h"
#import "Analytics.h"
#import "ObserverCount.h"
#import "UIImage+INaturalist.h"

static NSString *LeaderboardCellReuseID = @"LeaderboardCell";

@interface ExploreLeaderboardViewController () <UITableViewDataSource,UITableViewDelegate>
@property UITableView *leaderboardTableView;
@property NSArray *leaderboard;
@property UIActivityIndicatorView *loadingSpinner;
@end

@implementation ExploreLeaderboardViewController

#pragma mark - UIViewController lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.leaderboard = @[];
    
    self.title = NSLocalizedString(@"Leaderboard", @"Title for leaderboard page.");
    
    self.leaderboardTableView = ({
        UITableView *tv =[[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        tv.translatesAutoresizingMaskIntoConstraints = NO;
        
        [tv registerClass:[ExploreLeaderboardCell class] forCellReuseIdentifier:LeaderboardCellReuseID];
        tv.separatorColor = [UIColor darkGrayColor];
        
        tv.delegate = self;
        tv.dataSource = self;
        
        tv.tableFooterView = [UIView new];
        
        tv;
    });
    [self.view addSubview:self.leaderboardTableView];
    
    self.loadingSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
    self.loadingSpinner.hidden = YES;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:self.loadingSpinner];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.leaderboardTableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.leaderboardTableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.leaderboardTableView.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [self.leaderboardTableView.bottomAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.bottomAnchor],
    ]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.loadingSpinner.hidden = NO;
    [self.loadingSpinner startAnimating];
    
    [self.observationsController loadLeaderboardCompletion:^(NSArray *results, NSError *error) {
        
        if (error) {
            [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"Error loading leaderboard: %@",
                                                error.localizedDescription]];
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error loading leaderboard", @"error loading leaderboard title")
                                                                           message:error.localizedDescription
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
            return;
        }
        
        self.leaderboard = results;
        
        [self.leaderboardTableView reloadData];
        
        [self.loadingSpinner stopAnimating];
        self.loadingSpinner.hidden = YES;
    }];
}

#pragma mark - UITableView delegate/datasource


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.leaderboard.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ExploreLeaderboardCell *cell = (ExploreLeaderboardCell *)[tableView dequeueReusableCellWithIdentifier:LeaderboardCellReuseID];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [self configureCell:cell forIndexPath:indexPath];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0f;
}

- (void)configureCell:(ExploreLeaderboardCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    
    ObserverCount *count = [self.leaderboard objectAtIndex:indexPath.item];
    NSInteger obsCount = count.observationCount;
    NSInteger speciesCount = count.speciesCount;
    NSString *username = count.observer.login;
    NSURL *userIconUrl = count.observer.userIcon;
    
    cell.username.text = username;
    
    // the leaderboard API call can return users who are on the species leaderboard but not the
    // obs leaderboard, leaving them with 0 apparent observations in the JSON. this is obviously
    // incorrect, but we don't want to do another API call for every row, so just show * like on
    // the web.
    if (obsCount > 0) {
        NSString *obsCountBaseString = NSLocalizedString(@"Observations: %ld", @"observation count on the explore leaderboard.");
        cell.observationCount.text = [NSString stringWithFormat:obsCountBaseString, (long)obsCount];
    } else {
        cell.observationCount.text = NSLocalizedString(@"Observations: *", @"observation count on explore leaderboard when the user has species but not observations in the leaderboard.");
    }
    if (speciesCount > 0) {
        NSString *speciesCountBaseString = NSLocalizedString(@"Species: %ld", @"species count on the explore leaderboard.");
        cell.speciesCount.text = [NSString stringWithFormat:speciesCountBaseString, (long)speciesCount];
    } else {
        cell.speciesCount.text = NSLocalizedString(@"Species: *", @"observation count on explore leaderboard when the user has observations but not species in the leaderboard.");

    }
    
    if (userIconUrl) {
        [cell.userIcon setImageWithURL:userIconUrl];
    } else {
        cell.userIcon.image = [UIImage inat_defaultUserImage];
    }
    
    cell.rank.text = [NSString stringWithFormat:@"%ld", (long)indexPath.row + 1];
}

@end
