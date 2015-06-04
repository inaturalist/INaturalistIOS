//
//  ExploreLeaderboardViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/17/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <SVProgressHUD/SVProgressHUD.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <BlocksKit/BlocksKit.h>

#import "ExploreLeaderboardViewController.h"
#import "ExploreObservationsController.h"
#import "ExploreLeaderboardCell.h"
#import "ExploreLeaderboardHeader.h"
#import "Taxon.h"
#import "Analytics.h"

static NSString *LeaderboardCellReuseID = @"LeaderboardCell";

static NSString *kSpanYearKey = @"year";
static NSString *kSpanMonthKey = @"month";
static NSString *kSortObservationsKey = @"observations_count";
static NSString *kSortSpeciesKey = @"species_count";

@interface ExploreLeaderboardViewController () <UITableViewDataSource,UITableViewDelegate> {
    UITableView *leaderboardTableView;
    NSArray *leaderboard;
    ExploreLeaderboardHeader *header;
    NSString *sortKey, *spanKey;
}
@end

@implementation ExploreLeaderboardViewController

#pragma mark - UIViewController lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Leaderboard", @"Title for leaderboard page.");
    
    leaderboardTableView = ({
        UITableView *tv =[[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
        tv.translatesAutoresizingMaskIntoConstraints = NO;
        
        [tv registerClass:[ExploreLeaderboardCell class] forCellReuseIdentifier:LeaderboardCellReuseID];
        tv.separatorColor = [UIColor darkGrayColor];
        
        tv.delegate = self;
        tv.dataSource = self;
        
        tv;
    });
    [self.view addSubview:leaderboardTableView];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:leaderboardTableView
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:leaderboardTableView
                                                          attribute:NSLayoutAttributeCenterY
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterY
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:leaderboardTableView
                                                          attribute:NSLayoutAttributeHeight
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeHeight
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:leaderboardTableView
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeWidth
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    
    
}

- (void)viewWillAppear:(BOOL)animated {
    
    [[Analytics sharedClient] event:kAnalyticsEventNavigateExploreLeaderboard];
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Loading leaderboard", @"Loading message while a leaderboard is being downloaded from the web")];

    [self.observationsController loadLeaderboardSpan:ExploreLeaderboardSpanMonth
                                          completion:^(NSArray *results, NSError *error) {
                                              if (error) {
                                                  [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"Error loading leaderboard: %@",
                                                                                      error.localizedDescription]];
                                                  [SVProgressHUD showErrorWithStatus:error.localizedDescription];
                                                  return;
                                              }
                                              
                                              leaderboard = [results sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                                                  return [[obj2 valueForKeyPath:sortKey] compare:[obj1 valueForKeyPath:sortKey]];
                                              }];
                                              [leaderboardTableView reloadData];
                                              [SVProgressHUD showSuccessWithStatus:nil];

                                          }];
}

#pragma mark - UISegmentedControl targets

- (void)spanned {
    
    if (header.spanSelector.selectedSegmentIndex == 0) {
        spanKey = kSpanMonthKey;
    } else {
        spanKey = kSpanYearKey;
    }
    
    [SVProgressHUD showWithStatus:NSLocalizedString(@"Loading leaderboard", @"Loading message while a leaderboard is being downloaded from the web")];
    
    ExploreLeaderboardSpan span = [spanKey isEqualToString:kSpanYearKey] ? ExploreLeaderboardSpanYear : ExploreLeaderboardSpanMonth;
    [self.observationsController loadLeaderboardSpan:span
                                          completion:^(NSArray *results, NSError *error) {
                                              if (error) {
                                                  [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"Error loading leaderboard: %@",
                                                                                      error.localizedDescription]];
                                                  [SVProgressHUD showErrorWithStatus:error.localizedDescription];
                                                  return;
                                              }
                                              
                                              leaderboard = [results sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                                                  return [[obj2 valueForKeyPath:sortKey] compare:[obj1 valueForKeyPath:sortKey]];
                                              }];
                                              [leaderboardTableView reloadData];
                                              [SVProgressHUD showSuccessWithStatus:nil];
                                          }];
}

- (void)sorted {
    
    if (header.sortSelector.selectedSegmentIndex == 1) {
        sortKey = kSortSpeciesKey;
    } else {
        sortKey = kSortObservationsKey;
    }
    
    NSArray *oldLeaderboard = [leaderboard copy];
    
    leaderboard = [leaderboard sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [[obj2 valueForKeyPath:sortKey] compare:[obj1 valueForKeyPath:sortKey]];
    }];
    
    NSMutableArray *objsToMove = [NSMutableArray array];
    for (NSIndexPath *path in [leaderboardTableView indexPathsForVisibleRows]) {
        [objsToMove addObject:leaderboard[path.row]];
        [objsToMove addObject:oldLeaderboard[path.row]];
    }

    [leaderboardTableView beginUpdates];
    
    for (id obj in objsToMove) {
        
        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:[leaderboard indexOfObject:obj]
                                                       inSection:0];
        NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:[oldLeaderboard indexOfObject:obj]
                                                       inSection:0];
        
        [leaderboardTableView moveRowAtIndexPath:oldIndexPath toIndexPath:newIndexPath];
    }
    [leaderboardTableView endUpdates];

    [[leaderboardTableView visibleCells] enumerateObjectsUsingBlock:^(ExploreLeaderboardCell *cell, NSUInteger idx, BOOL *stop) {
        [self configureCell:cell forIndexPath:[leaderboardTableView indexPathForCell:cell]];
    }];
}

#pragma mark - UITableView delegate/datasource


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return leaderboard.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ExploreLeaderboardCell *cell = (ExploreLeaderboardCell *)[tableView dequeueReusableCellWithIdentifier:LeaderboardCellReuseID];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [self configureCell:cell forIndexPath:indexPath];

    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (!header) {
        header = [[ExploreLeaderboardHeader alloc] initWithFrame:CGRectMake(0, 0,
                                                                            tableView.bounds.size.width,
                                                                            [tableView.delegate tableView:tableView heightForHeaderInSection:section])];
        header.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        
        // default to sort by observations
        sortKey = kSortObservationsKey;
        header.sortSelector.selectedSegmentIndex = 0;
        
        [header.sortSelector addTarget:self
                                action:@selector(sorted)
                      forControlEvents:UIControlEventValueChanged];
        
        // default to span of a month
        spanKey = kSpanMonthKey;
        header.spanSelector.selectedSegmentIndex = 0;
        
        [header.spanSelector addTarget:self
                                action:@selector(spanned)
                      forControlEvents:UIControlEventValueChanged];
        
        __block NSString *locationProject = @"";        // location and/or project
        __block NSString *taxonPerson = @"";            // organism and/or person
        
        [self.observationsController.activeSearchPredicates bk_each:^(ExploreSearchPredicate *predicate) {
            BOOL predicateIsLocative = NO;
            
            switch (predicate.type) {
                case ExploreSearchPredicateTypeLocation:
                case ExploreSearchPredicateTypeProject:
                    predicateIsLocative = YES;
                case ExploreSearchPredicateTypeCritter:
                case ExploreSearchPredicateTypePerson:
                default:
                    break;
            }
            
            NSString *str = predicateIsLocative ? locationProject : taxonPerson;
            
            if ([str isEqualToString:@""]) {
                str = [predicate.searchTerm copy];
            } else {
                str = [str stringByAppendingFormat:@" %@", predicate.searchTerm];
            }
            
            if (predicateIsLocative) {
                locationProject = str;
            } else {
                taxonPerson = str;
            }
        }];
        
        if (!locationProject || [locationProject isEqualToString:@""]) {
            locationProject = NSLocalizedString(@"Worldwide", @"Indicator that the leaderboard is global, not specific to a project or a place");
        }
        if (!taxonPerson || [taxonPerson isEqualToString:@""]) {
            taxonPerson = NSLocalizedString(@"All Species", @"Indicator that the leaderboard applies to all species, not just a specific taxon.");
        }
        
        header.title.text = [NSString stringWithFormat:@"%@, %@", locationProject, taxonPerson];
    
    }
    
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 100.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.0f;
}

- (void)configureCell:(ExploreLeaderboardCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *leaderboardRecord = [leaderboard objectAtIndex:indexPath.item];
    NSNumber *obsCount = [leaderboardRecord valueForKeyPath:kSortObservationsKey];
    NSNumber *speciesCount = [leaderboardRecord valueForKeyPath:kSortSpeciesKey];
    NSString *username = [leaderboardRecord valueForKeyPath:@"user_login"];
    NSString *userIconUrl = [leaderboardRecord valueForKeyPath:@"user_icon"];
    
    cell.username.text = username;
    cell.observationCount.text = [NSString stringWithFormat:@"Observations: %ld", (long)obsCount.integerValue];
    cell.speciesCount.text = [NSString stringWithFormat:@"Species: %ld", (long)speciesCount.integerValue];
    
    // embolden the sort key for the leaderboard
    if ([sortKey isEqualToString:kSortObservationsKey]) {
        cell.observationCount.font = [UIFont boldSystemFontOfSize:cell.observationCount.font.pointSize];
        cell.observationCount.textColor = [UIColor darkGrayColor];
        cell.speciesCount.font = [UIFont systemFontOfSize:cell.speciesCount.font.pointSize];
        cell.speciesCount.textColor = [UIColor lightGrayColor];
    } else {
        cell.observationCount.font = [UIFont systemFontOfSize:cell.observationCount.font.pointSize];
        cell.observationCount.textColor = [UIColor lightGrayColor];
        cell.speciesCount.font = [UIFont boldSystemFontOfSize:cell.speciesCount.font.pointSize];
        cell.speciesCount.textColor = [UIColor darkGrayColor];
    }
    
    if (![userIconUrl isEqual:[NSNull null]] && ![userIconUrl isEqualToString:@""]) {
        [cell.userIcon sd_setImageWithURL:[NSURL URLWithString:userIconUrl]];
    } else {
        [cell.userIcon sd_setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/attachment_defaults/users/icons/defaults/thumb.png",
                                                                INatMediaBaseURL]]];
    }
    
    [cell.sortControl addTarget:self action:@selector(sorted) forControlEvents:UIControlEventTouchUpInside];
    
    cell.rank.text = [NSString stringWithFormat:@"%ld", (long)indexPath.row + 1];
}

@end
