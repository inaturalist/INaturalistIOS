//
//  ProjectDetailSpeciesViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/23/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <AFNetworking/UIImageView+AFNetworking.h>
#import <UIColor-HTMLColors/UIColor+HTMLColors.h>
#import <RestKit/RestKit.h>

#import "ProjectDetailSpeciesViewController.h"
#import "SpeciesCount.h"
#import "ExploreTaxon.h"
#import "SpeciesCountCell.h"
#import "INatReachability.h"

@implementation ProjectDetailSpeciesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.backgroundView = ({
        UILabel *label = [UILabel new];
        label.numberOfLines = 0;
        label.textAlignment = NSTextAlignmentCenter;

        label.attributedText = ({
            NSString *emptyTitle;
            if ([[INatReachability sharedClient] isNetworkReachable]) {
                emptyTitle = NSLocalizedString(@"There are no observations for this project yet. Check back soon!", nil);
            } else {
                emptyTitle = NSLocalizedString(@"No network connection. :(", nil);
            }
            NSDictionary *attrs = @{
                                    NSForegroundColorAttributeName: [UIColor colorWithHexString:@"#505050"],
                                    NSFontAttributeName: [UIFont systemFontOfSize:17.0f],
                                    };
            [[NSAttributedString alloc] initWithString:emptyTitle
                                            attributes:attrs];
            
        });
        label;
    });
    self.totalCount = 0;
    self.tableView.tableFooterView = [UIView new];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    tableView.backgroundView.hidden = (self.speciesCounts.count > 0);
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

    if ([count.taxon.scientificName isEqualToString:count.taxon.commonName] || count.taxon.commonName == nil || [count.taxon.commonName isEqualToString:@""]) {
        // no common name, so only show the scientific name in the main label
        cell.taxonNameLabel.text = count.taxon.scientificName;
        cell.taxonSecondaryNameLabel.text = nil;
        
        if ([count isGenusOrLower]) {
            cell.taxonNameLabel.font = [UIFont italicSystemFontOfSize:17];
        } else {
            cell.taxonNameLabel.font = [UIFont systemFontOfSize:17];
            cell.taxonNameLabel.text = [NSString stringWithFormat:@"%@ %@",
                                        [[count.taxon rankName] capitalizedString], count.taxon.scientificName];
        }
    } else {
        // show both common & scientfic names
        cell.taxonNameLabel.text = count.taxon.commonName;
        cell.taxonNameLabel.font = [UIFont systemFontOfSize:17];
        
        if ([count isGenusOrLower]) {
            cell.taxonSecondaryNameLabel.font = [UIFont italicSystemFontOfSize:15];
            cell.taxonSecondaryNameLabel.text = count.taxon.scientificName;
        } else {
            cell.taxonSecondaryNameLabel.font = [UIFont systemFontOfSize:15];
            cell.taxonSecondaryNameLabel.text = [NSString stringWithFormat:@"%@ %@",
                                                 [count.taxon.rankName capitalizedString], count.taxon.scientificName];
            
        }
    }
    
    [cell.taxonImageView setImageWithURL:count.taxon.photoUrl];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SpeciesCount *count = self.speciesCounts[indexPath.item];    
    [self.projectDetailDelegate inat_performSegueWithIdentifier:@"taxon" object:count.taxon];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.containedScrollViewDelegate containedScrollViewDidScroll:scrollView];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self.containedScrollViewDelegate containedScrollViewDidStopScrolling:scrollView];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [self.containedScrollViewDelegate containedScrollViewDidStopScrolling:scrollView];
    }
}

@end
