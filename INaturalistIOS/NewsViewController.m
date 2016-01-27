//
//  NewsViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 1/13/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>
#import <FontAwesomeKit/FAKIonIcons.h>
#import <YLMoment/YLMoment.h>
#import <NSString_stripHtml/NSString_stripHTML.h>
#import <SVPullToRefresh/SVPullToRefresh.h>

#import "NewsViewController.h"
#import "ProjectPost.h"
#import "UIColor+INaturalist.h"
#import "Analytics.h"
#import "User.h"
#import "NewsitemViewController.h"
#import "ProjectPostCell.h"
#import "Project.h"
#import "UIColor+INaturalist.h"

static UIImage *briefcase;

@interface NewsViewController () <NSFetchedResultsControllerDelegate, RKObjectLoaderDelegate, RKRequestDelegate> {
    NSFetchedResultsController *_frc;
}

@property (readonly) NSFetchedResultsController *frc;
@property RKObjectLoader *objectLoader;

@end

@implementation NewsViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        
        self.title = NSLocalizedString(@"News", nil);
        
        self.tabBarItem.image = ({
            FAKIcon *news = [FAKIonIcons iosListOutlineIconWithSize:35];
            [news addAttribute:NSForegroundColorAttributeName value:[UIColor inatInactiveGreyTint]];
            [[news imageWithSize:CGSizeMake(34, 45)] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        });
        
        self.tabBarItem.selectedImage = ({
            FAKIcon *news = [FAKIonIcons iosListIconWithSize:35];
            [news imageWithSize:CGSizeMake(34, 45)];
        });
        
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
    
    // tableview configuration
    self.refreshControl.tintColor = [UIColor inatTint];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"newsItem"];

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


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [[Analytics sharedClient] timedEvent:kAnalyticsEventNavigateNewsList];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[Analytics sharedClient] endTimedEvent:kAnalyticsEventNavigateNewsList];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"detail"]) {
        NewsItemViewController *vc = (NewsItemViewController *)[segue destinationViewController];
        vc.post = (ProjectPost *)sender;
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
    
    ProjectPostCell *cell = [tableView dequeueReusableCellWithIdentifier:@"projectPost"
                                                            forIndexPath:indexPath];
    
    ProjectPost *newsItem = [self.frc objectAtIndexPath:indexPath];
    if (newsItem.projectTitle) {
        cell.projectName.text = newsItem.projectTitle;
        NSURL *iconURL = [NSURL URLWithString:newsItem.projectIconUrl];
        if (iconURL) {
            [cell.projectImageView sd_setImageWithURL:iconURL];
        } else {
            cell.projectImageView.image = briefcase;
        }
    } else {
        // we have an outdated version of this object, refresh it
        // TODO: this will only happen for a single development version
        // TODO: remove this code in production
        [self reloadNewsItem:newsItem];
        
        // too much work to do in the main queue?
        NSFetchRequest *projectRequest = [Project fetchRequest];
        projectRequest.predicate = [NSPredicate predicateWithFormat:@"recordID = %@", newsItem.projectID];
        
        NSError *fetchError;
        Project *p = [[[Project managedObjectContext] executeFetchRequest:projectRequest
                                                                    error:&fetchError] firstObject];
        if (fetchError) {
            [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"error fetching: %@",
                                                fetchError.localizedDescription]];
        } else if (p) {
            cell.projectName.text = p.title;
            NSURL *iconURL = [NSURL URLWithString:p.iconURL];
            if (iconURL) {
                [cell.projectImageView sd_setImageWithURL:iconURL];
            }
        } else {
            cell.projectImageView.image = briefcase;
        }
    }
    
    // this is probably sloooooooow. too slow to do on
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *url = nil;
        NSString *htmlString = newsItem.body;
        NSScanner *theScanner = [NSScanner scannerWithString:htmlString];
        // find start of IMG tag
        [theScanner scanUpToString:@"<img" intoString:nil];
        if (![theScanner isAtEnd]) {
            [theScanner scanUpToString:@"src" intoString:nil];
            NSCharacterSet *charset = [NSCharacterSet characterSetWithCharactersInString:@"\"'"];
            [theScanner scanUpToCharactersFromSet:charset intoString:nil];
            [theScanner scanCharactersFromSet:charset intoString:nil];
            [theScanner scanUpToCharactersFromSet:charset intoString:&url];
            NSURL *imageURL = [NSURL URLWithString:url];
            if (imageURL) {
                [cell.postImageView sd_setImageWithURL:imageURL];
            }
        }
    });
    
    cell.postTitle.text = newsItem.title;
    NSString *strippedBody = [newsItem.body stringByStrippingHTML];
    cell.postBody.text = [strippedBody stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    cell.postedAt.text = [[YLMoment momentWithDate:newsItem.publishedAt] fromNow];
    
    return cell;
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ProjectPost *newsItem = [self.frc objectAtIndexPath:indexPath];
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
    if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        return;
    }
    
    NSString *path = @"/posts/for_project_user.json";
    
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.frc sections][0];
    if ([sectionInfo numberOfObjects] > 0) {
        // most recent item will be first
        ProjectPost *mostRecentPost = [self.frc objectAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
        path = [path stringByAppendingString:[NSString stringWithFormat:@"?newer_than=%ld", (long)mostRecentPost.recordID.integerValue]];
    }
    
    [[Analytics sharedClient] debugLog:@"Network - Fetch New News"];
    [[RKObjectManager sharedManager] loadObjectsAtResourcePath:path
                                                    usingBlock:^(RKObjectLoader *loader) {
                                                        loader.objectMapping = [ProjectPost mapping];
                                                        loader.delegate = self;
                                                    }];
}

- (void)loadOldNews {
    
    // silently do nothing if we're offline
    if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        return;
    }
    
    NSString *path = @"/posts/for_project_user.json";
    
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.frc sections][0];
    if ([sectionInfo numberOfObjects] > 0) {
        // most recent item will be last
        
        ProjectPost *oldestPost = [self.frc objectAtIndexPath:[NSIndexPath indexPathForItem:[sectionInfo numberOfObjects] - 1
                                                                                      inSection:0]];
        path = [path stringByAppendingString:[NSString stringWithFormat:@"?older_than=%ld", (long)oldestPost.recordID.integerValue]];
    }
    
    [[Analytics sharedClient] debugLog:@"Network - Fetch Old News"];
    [[RKObjectManager sharedManager] loadObjectsAtResourcePath:path
                                                    usingBlock:^(RKObjectLoader *loader) {
                                                        loader.objectMapping = [ProjectPost mapping];
                                                        loader.delegate = self;
                                                    }];
}

- (void)reloadNewsItem:(ProjectPost *)post {
    // silently do nothing if we're offline
    if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        return;
    }
    
    NSString *path = @"/posts/for_project_user.json";
    path = [path stringByAppendingString:[NSString stringWithFormat:@"?older_than=%ld", (long)post.recordID.integerValue + 1]];
    path = [path stringByAppendingString:[NSString stringWithFormat:@"&newer_than=%ld", (long)post.recordID.integerValue - 1]];
    
    [[Analytics sharedClient] debugLog:@"Network - Re-fetch a News Item"];
    [[RKObjectManager sharedManager] loadObjectsAtResourcePath:path
                                                    usingBlock:^(RKObjectLoader *loader) {
                                                        loader.objectMapping = [ProjectPost mapping];
                                                        loader.delegate = self;
                                                    }];
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
        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"ProjectPost"];
        
        // sort by common name, if available
        request.sortDescriptors = @[
                                    [[NSSortDescriptor alloc] initWithKey:@"publishedAt" ascending:NO],
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
    
    // if this is the project posts callback, end the refresh
    if ([objectLoader.URL.absoluteString rangeOfString:@"posts/for_project_user.json"].location != NSNotFound) {
        // in case load was triggered by pull to refresh, stop the animation
        [self.refreshControl endRefreshing];
        // in case load was triggered by infinite scrolling, stop the animation
        [self.tableView.infiniteScrollingView stopAnimating];
    }
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
    // workaround an objectloader dealloc bug in restkit
    self.objectLoader = objectLoader;
    
    // in case load was triggered by pull to refresh, stop the animation
    [self.refreshControl endRefreshing];
    // in case load was triggered by infinite scrolling, stop the animation
    [self.tableView.infiniteScrollingView stopAnimating];
    
    [[[UIAlertView alloc] initWithTitle:@"Error"
                                message:error.localizedDescription
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"OK",nil)
                      otherButtonTitles:nil] show];
}



@end
