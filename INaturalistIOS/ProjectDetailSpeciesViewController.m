//
//  ProjectDetailSpeciesViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/23/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>
#import <DZNEmptyDataSet/UIScrollView+EmptyDataSet.h>
#import <UIColor-HTMLColors/UIColor+HTMLColors.h>

#import "ProjectDetailSpeciesViewController.h"
#import "SpeciesCount.h"
#import "Taxon.h"
#import "SpeciesCountCell.h"

@interface ProjectDetailSpeciesViewController () <DZNEmptyDataSetSource>
@end

@implementation ProjectDetailSpeciesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.emptyDataSetSource = self;
    self.totalCount = 0;
    self.tableView.tableFooterView = [UIView new];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.speciesCounts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SpeciesCountCell *cell = [tableView dequeueReusableCellWithIdentifier:@"speciesCount"
                                                             forIndexPath:indexPath];
    
    SpeciesCount *count = self.speciesCounts[indexPath.item];
    
    cell.countLabel.text = [NSString stringWithFormat:@"%ld", (long)count.speciesCount];

    if ([count.scientificName isEqualToString:count.commonName] || count.commonName == nil || [count.commonName isEqualToString:@""]) {
        // no common name, so only show the scientific name in the main label
        cell.taxonNameLabel.text = count.scientificName;
        cell.taxonSecondaryNameLabel.text = nil;
        
        if ([count isGenusOrLower]) {
            cell.taxonNameLabel.font = [UIFont italicSystemFontOfSize:17];
        } else {
            cell.taxonNameLabel.font = [UIFont systemFontOfSize:17];
            cell.taxonNameLabel.text = [NSString stringWithFormat:@"%@ %@",
                                        [[count speciesRank] capitalizedString], count.scientificName];
        }
    } else {
        // show both common & scientfic names
        cell.taxonNameLabel.text = count.commonName;
        cell.taxonNameLabel.font = [UIFont systemFontOfSize:17];
        
        if ([count isGenusOrLower]) {
            cell.taxonSecondaryNameLabel.font = [UIFont italicSystemFontOfSize:15];
            cell.taxonSecondaryNameLabel.text = count.scientificName;
        } else {
            cell.taxonSecondaryNameLabel.font = [UIFont systemFontOfSize:15];
            cell.taxonSecondaryNameLabel.text = [NSString stringWithFormat:@"%@ %@",
                                                 [[count speciesRank] capitalizedString], count.scientificName];
            
        }
    }
    
    [cell.taxonImageView sd_setImageWithURL:[NSURL URLWithString:count.squarePhotoUrl]];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SpeciesCount *count = self.speciesCounts[indexPath.item];    
    [self.projectDetailDelegate inat_performSegueWithIdentifier:@"taxon" object:@([count taxonId])];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.containedScrollViewDelegate containedScrollViewDidScroll:scrollView];
}

#pragma mark - DZNEmptyDataSource

- (UIView *)customViewForEmptyDataSet:(UIScrollView *)scrollView {
    if (self.speciesCounts == nil && [[RKClient sharedClient] isNetworkReachable]) {
        UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        activityView.color = [UIColor colorWithHexString:@"#8f8e94"];
        activityView.backgroundColor = [UIColor colorWithHexString:@"#ebebf1"];
        [activityView startAnimating];
        
        return activityView;
    } else {
        return nil;
    }
}

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView {
    NSString *emptyTitle;
    if ([[RKClient sharedClient] isNetworkReachable]) {
        emptyTitle = NSLocalizedString(@"There are no observations for this project yet. Check back soon!", nil);
    } else {
        emptyTitle = NSLocalizedString(@"No network connection. :(", nil);
    }
    NSDictionary *attrs = @{
                            NSForegroundColorAttributeName: [UIColor colorWithHexString:@"#505050"],
                            NSFontAttributeName: [UIFont systemFontOfSize:17.0f],
                            };
    return [[NSAttributedString alloc] initWithString:emptyTitle
                                           attributes:attrs];
}

@end
