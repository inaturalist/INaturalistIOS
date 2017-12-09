//
//  NewsViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 1/13/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <AFNetworking/UIImageView+AFNetworking.h>
#import <FontAwesomeKit/FAKIonIcons.h>
#import <YLMoment/YLMoment.h>
#import <NSString_stripHtml/NSString_stripHTML.h>
#import <SVPullToRefresh/SVPullToRefresh.h>
#import <RestKit/RestKit.h>

#import "SiteNewsViewController.h"
#import "NewsItem.h"
#import "UIColor+INaturalist.h"
#import "Analytics.h"
#import "User.h"
#import "NewsItemViewController.h"
#import "NewsItemCell.h"
#import "Project.h"
#import "UIColor+INaturalist.h"
#import "INaturalistAppDelegate.h"
#import "LoginController.h"
#import "INatReachability.h"

static UIImage *briefcase;

@interface SiteNewsViewController () <NSFetchedResultsControllerDelegate, RKObjectLoaderDelegate, RKRequestDelegate, UITableViewDelegate, UITableViewDataSource> {
    NSFetchedResultsController *_frc;
}

@property (readonly) NSFetchedResultsController *frc;
@property RKObjectLoader *objectLoader;
@property IBOutlet UITableView *tableView;
@end

@implementation SiteNewsViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        
        briefcase = ({
            FAKIcon *briefcaseOutline = [FAKIonIcons iosBriefcaseOutlineIconWithSize:35];
            [briefcaseOutline addAttribute:NSForegroundColorAttributeName value:[UIColor inatTint]];
            [briefcaseOutline imageWithSize:CGSizeMake(34, 45)];
        });
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    // hide empty cell divider lines
    self.tableView.tableFooterView = [UIView new];
    
    [self.tableView registerClass:[NewsItemCell class]
           forCellReuseIdentifier:@"newsItem"];
    
    // tableview configuration
    //self.refreshControl.tintColor = [UIColor inatTint];
    
    // infinite scroll for tableview
    __weak typeof(self) weakSelf = self;
    [self.tableView addInfiniteScrollingWithActionHandler:^{
        [weakSelf loadOldNews];
    }];
    self.tableView.showsInfiniteScrolling = YES;
    
    // fetch content from the server
    [self refresh];
    
    NSError *err;
    [self.frc performFetch:&err];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [UIView animateWithDuration:0.3 animations:^{
        [self.navigationController.navigationBar setBackgroundImage:nil
                                                      forBarMetrics:UIBarMetricsDefault];
        self.navigationController.navigationBar.shadowImage = nil;
        self.navigationController.navigationBar.translucent = NO;
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"detail"]) {
        NewsItemViewController *vc = (NewsItemViewController *)[segue destinationViewController];
        vc.newsItem = (NewsItem *)sender;
    }
}

- (void)dealloc {
    [[[RKClient sharedClient] requestQueue] cancelRequestsWithDelegate:self];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.frc sections][0];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NewsItemCell *cell = [tableView dequeueReusableCellWithIdentifier:@"newsItem"
                                                         forIndexPath:indexPath];
    
    NewsItem *newsItem = [self.frc objectAtIndexPath:indexPath];
    
    if (self.project) {
        cell.newsCategoryTitle.text = self.project.title;
        NSURL *iconURL = [NSURL URLWithString:self.project.iconURL];
        if (iconURL) {
            [cell.newsCategoryImageView setImageWithURL:iconURL];
        } else {
            cell.newsCategoryImageView.image = briefcase;
        }
    } else {
        cell.newsCategoryTitle.text = newsItem.parentTitleText;
        NSURL *iconURL = [NSURL URLWithString:newsItem.parentIconUrl];
        if (iconURL) {
            [cell.newsCategoryImageView setImageWithURL:iconURL];
        } else {
            cell.newsCategoryImageView.image = briefcase;
        }
    }
    
    NSURL *coverImageURL = [NSURL URLWithString:newsItem.postCoverImageUrl];
    if (coverImageURL) {
        [cell.postImageView setImageWithURL:coverImageURL];
        [cell showPostImageView:YES];
    } else {
        [cell showPostImageView:NO];
    }
    
    cell.postTitle.text = newsItem.postTitle;
    cell.postBody.text = newsItem.postPlainTextExcerpt;
    cell.postedAt.text = [[YLMoment momentWithDate:newsItem.postPublishedAt] fromNowWithSuffix:NO];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NewsItem *newsItem = [self.frc objectAtIndexPath:indexPath];
    
    [[Analytics sharedClient] event:kAnalyticsEventNewsOpenArticle
                     withProperties:@{
                                      @"ParentType": [newsItem parentTypeString] ?: @"",
                                      @"ParentName": [newsItem parentTitleText] ?: @"",
                                      @"ArticleTitle": [newsItem postTitle] ?: @"",
                                      }];
    
    [self performSegueWithIdentifier:@"detail" sender:newsItem];
}

#pragma mark - UIControl targets

- (IBAction)pullToRefresh:(id)sender {
    [self refresh];
}

#pragma mark - refresh helpers

- (void)refresh {
    [self loadNewNews];
}

- (void)loadNewNews {
    
    // silently do nothing if we're offline
    if (![[INatReachability sharedClient] isNetworkReachable]) {
        return;
    }
    
    NSString *path = [self newsItemEndpoint];
    
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.frc sections][0];
    if ([sectionInfo numberOfObjects] > 0) {
        // most recent item will be first
        NewsItem *mostRecentItem = [self.frc objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
        path = [path stringByAppendingString:[NSString stringWithFormat:@"?newer_than=%ld", (long)mostRecentItem.recordID.integerValue]];
    }
    
    [[Analytics sharedClient] debugLog:@"Network - Fetch New News"];
    [[RKObjectManager sharedManager] loadObjectsAtResourcePath:path
                                                    usingBlock:^(RKObjectLoader *loader) {
                                                        loader.objectMapping = [NewsItem mapping];
                                                        loader.delegate = self;
                                                    }];
}

- (void)loadOldNews {
    
    // silently do nothing if we're offline
    if (![[INatReachability sharedClient] isNetworkReachable]) {
        return;
    }
    
    NSString *path = [self newsItemEndpoint];
    
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.frc sections][0];
    if ([sectionInfo numberOfObjects] > 0) {
        // most recent item will be last
        NewsItem *oldestItem = [self.frc objectAtIndexPath:[NSIndexPath indexPathForItem:[sectionInfo numberOfObjects] - 1
                                                                               inSection:0]];
        path = [path stringByAppendingString:[NSString stringWithFormat:@"?older_than=%ld", (long)oldestItem.recordID.integerValue]];
    }
    
    [[Analytics sharedClient] debugLog:@"Network - Fetch Old News"];
    [[RKObjectManager sharedManager] loadObjectsAtResourcePath:path
                                                    usingBlock:^(RKObjectLoader *loader) {
                                                        loader.objectMapping = [NewsItem mapping];
                                                        loader.delegate = self;
                                                    }];
}

- (NSString *)newsItemEndpoint {
    if (self.project) {
        return [NSString stringWithFormat:@"/projects/%ld/journal.json",
                (long)self.project.recordID.integerValue];
    } else {
        return @"/posts/for_user.json";
    }
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:@[ newIndexPath ]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:@[ indexPath ]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self.tableView reloadRowsAtIndexPaths:@[ indexPath ]
                                  withRowAnimation:UITableViewRowAnimationNone];
            break;
            
        case NSFetchedResultsChangeMove:
            [self.tableView moveRowAtIndexPath:indexPath
                                   toIndexPath:newIndexPath];
            break;
            
        default:
            break;
    }
}

#pragma mark - Fetched Results Controller helper

- (NSFetchedResultsController *)frc {
    
    if (!_frc) {
        // NSFetchedResultsController request for my observations
        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"NewsItem"];
        
        if (self.project) {
            request.predicate = [NSPredicate predicateWithFormat:@"parentTypeString == 'Project' AND parentRecordID == %@",
                                 self.project.recordID];
        }
        
        // sort by common name, if available
        request.sortDescriptors = @[
                                    [[NSSortDescriptor alloc] initWithKey:@"postPublishedAt" ascending:NO],
                                    ];
        
        // setup our fetched results controller
        _frc = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                   managedObjectContext:[NSManagedObjectContext defaultContext]
                                                     sectionNameKeyPath:nil
                                                              cacheName:nil];
        
        // update our tableview based on changes in the fetched results
        _frc.delegate = self;
    }
    
    return _frc;
}

#pragma mark - RKObjectLoaderDelegate

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects {
    
    NSDate *now = [NSDate date];
    for (INatModel *o in objects) {
        [o setSyncedAt:now];
    }
    
    NSError *error = nil;
    [[[RKObjectManager sharedManager] objectStore] save:&error];
    
    // check for new activity
    NSError *err;
    [self.frc performFetch:&err];
    
    // in case load was triggered by pull to refresh, stop the animation
    //[self.refreshControl endRefreshing];
    // in case load was triggered by infinite scrolling, stop the animation
    [self.tableView.infiniteScrollingView stopAnimating];
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
    // workaround an objectloader dealloc bug in restkit
    self.objectLoader = objectLoader;
    
    // in case load was triggered by pull to refresh, stop the animation
    //[self.refreshControl endRefreshing];
    // in case load was triggered by infinite scrolling, stop the animation
    [self.tableView.infiniteScrollingView stopAnimating];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Error", nil)
                                                                   message:error.localizedDescription
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}



@end
