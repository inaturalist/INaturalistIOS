//
//  ProjectDetailObserversViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/23/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>
#import <DZNEmptyDataSet/UIScrollView+EmptyDataSet.h>
#import <UIColor-HTMLColors/UIColor+HTMLColors.h>

#import "ProjectDetailObserversViewController.h"
#import "ObserverCount.h"
#import "ObserverCountCell.h"
#import "UIImage+INaturalist.h"

@interface ProjectDetailObserversViewController () <DZNEmptyDataSetSource>
@end

@implementation ProjectDetailObserversViewController

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
    return self.observerCounts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ObserverCountCell *cell = [tableView dequeueReusableCellWithIdentifier:@"observerCount"
                                                              forIndexPath:indexPath];
    
    ObserverCount *count = self.observerCounts[indexPath.item];
    cell.observerNameLabel.text = count.observerName;
    [cell.observerNameLabel sizeToFit];
    cell.observerObservationsCountLabel.text = [NSString stringWithFormat:@"%ld", count.observationCount];
    [cell.observerObservationsCountLabel sizeToFit];
    if (count.observerIconUrl) {
        [cell.observerImageView sd_setImageWithURL:[NSURL URLWithString:count.observerIconUrl]];
    } else {
        cell.observerImageView.image = [UIImage inat_defaultUserImage];
    }

    return cell;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self.containedScrollViewDelegate containedScrollViewDidScroll:scrollView];
}

#pragma mark - DZNEmptyDataSource

- (UIView *)customViewForEmptyDataSet:(UIScrollView *)scrollView {
    if (self.observerCounts == nil && [[RKClient sharedClient] isNetworkReachable]) {
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
