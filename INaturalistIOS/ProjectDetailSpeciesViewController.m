//
//  ProjectDetailSpeciesViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/23/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

@import AFNetworking;
@import UIColor_HTMLColors;

#import "ProjectDetailSpeciesViewController.h"
#import "SpeciesCount.h"
#import "ExploreTaxon.h"
#import "SpeciesCountCell.h"
#import "INatReachability.h"

@implementation ProjectDetailSpeciesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configureEmptyView];
    
    self.totalCount = 0;
    self.tableView.tableFooterView = [UIView new];
}

- (void)reloadDataViews {
    [self configureEmptyView];
    [self.tableView reloadData];
}

- (void)configureEmptyView {
    self.tableView.backgroundView = ({
        UILabel *label = [UILabel new];
        label.numberOfLines = 0;
        label.textAlignment = NSTextAlignmentCenter;

        label.attributedText = ({
            NSString *emptyTitle;
            if ([[INatReachability sharedClient] isNetworkReachable]) {
                if (self.hasFetchedSpecies) {
                    emptyTitle = NSLocalizedString(@"There are no observations for this project yet. Check back soon!", nil);
                } else {
                    emptyTitle = NSLocalizedString(@"Loading...", nil);
                }
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
    
    cell.taxonNameLabel.text = count.taxon.displayFirstName;
    if (count.taxon.displayFirstNameIsItalicized) {
        cell.taxonNameLabel.font = [UIFont italicSystemFontOfSize:cell.taxonNameLabel.font.pointSize];
    }
    
    cell.taxonSecondaryNameLabel.text = count.taxon.displaySecondName;
    if (count.taxon.displaySecondNameIsItalicized) {
        cell.taxonSecondaryNameLabel.font = [UIFont italicSystemFontOfSize:cell.taxonSecondaryNameLabel.font.pointSize];
    }
        
    [cell.taxonImageView setImageWithURL:count.taxon.photoUrl];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SpeciesCount *count = self.speciesCounts[indexPath.item];
    NSLog(@"taxon id is %ld", count.taxon.taxonId);
    [self.projectDetailDelegate inat_performSegueWithIdentifier:@"taxon" object:@(count.taxon.taxonId)];
}

@end
