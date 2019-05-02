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
#import <Realm/Realm.h>

#import "SiteNewsViewController.h"
#import "UIColor+INaturalist.h"
#import "Analytics.h"
#import "NewsItemViewController.h"
#import "NewsItemCell.h"
#import "UIColor+INaturalist.h"
#import "INaturalistAppDelegate.h"
#import "LoginController.h"
#import "INatReachability.h"
#import "PostsAPI.h"
#import "ExplorePost.h"
#import "ExplorePostRealm.h"

static UIImage *briefcase;

@interface SiteNewsViewController () <UITableViewDelegate, UITableViewDataSource>
@property IBOutlet UITableView *tableView;
@property RLMResults <ExplorePostRealm *> *posts;
@end

@implementation SiteNewsViewController

#pragma mark our API for post/news operations

- (PostsAPI *)postsApi {
    static PostsAPI *_api = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _api = [[PostsAPI alloc] init];
    });
    return _api;
}

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
    
    // infinite scroll for tableview
    __weak typeof(self) weakSelf = self;
    [self.tableView addInfiniteScrollingWithActionHandler:^{
        [weakSelf fetchPostsNew:NO];
    }];
    self.tableView.showsInfiniteScrolling = YES;
    
    // setup realm fetches
    if (self.project) {
        self.posts = [ExplorePostRealm objectsWhere:@"parentType=='Project' && parentId==%ld",self.project.projectId];
    } else {
        self.posts = [ExplorePostRealm objectsWhere:@"parentType=='Site'",self.project.projectId];
    }
    self.posts = [self.posts sortedResultsUsingDescriptors:[self sortDescriptorsForNewsPosts]];
    
    // fetch content from the server
    [self fetchPostsNew:YES];
}

- (NSArray <RLMSortDescriptor *> *)sortDescriptorsForNewsPosts {
    return @[
             [RLMSortDescriptor sortDescriptorWithKeyPath:@"publishedAt" ascending:NO],
             ];
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
        vc.post = (ExplorePostRealm *)sender;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.posts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NewsItemCell *cell = [tableView dequeueReusableCellWithIdentifier:@"newsItem"
                                                         forIndexPath:indexPath];
    
    ExplorePostRealm *epr = [self.posts objectAtIndex:indexPath.item];
    
    if (self.project) {
        cell.newsCategoryTitle.text = self.project.title;
    
        if (self.project.iconUrl) {
            [cell.newsCategoryImageView setImageWithURL:self.project.iconUrl];
        } else {
            cell.newsCategoryImageView.image = briefcase;
        }
    } else {
        cell.newsCategoryTitle.text = epr.parentSiteShortName;
        
        if (epr.parentIconUrl) {
            [cell.newsCategoryImageView setImageWithURL:epr.parentIconUrl];
        } else {
            cell.newsCategoryImageView.image = briefcase;
        }
    }
    
    if (epr.coverImageUrl) {
        [cell.postImageView setImageWithURL:epr.coverImageUrl];
        [cell showPostImageView:YES];
    } else {
        [cell showPostImageView:NO];
    }
    
    cell.postTitle.text = epr.title;
    cell.postBody.text = epr.excerpt;
    cell.postedAt.text = [[YLMoment momentWithDate:epr.publishedAt] fromNowWithSuffix:NO];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ExplorePostRealm *post = [self.posts objectAtIndex:indexPath.item];
    
    [[Analytics sharedClient] event:kAnalyticsEventNewsOpenArticle
                     withProperties:@{
                                      @"ParentType": [post parentType] ?: @"",
                                      @"ArticleTitle": [post title] ?: @"",
                                      }];
    
    [self performSegueWithIdentifier:@"detail" sender:post];
}

#pragma mark - UIControl targets

- (IBAction)pullToRefresh:(id)sender {
    [self fetchPostsNew:YES];
}

#pragma mark - refresh helper

- (void)fetchPostsNew:(BOOL)fetchNewPosts {
    // silently do nothing if we're offline
    if (![[INatReachability sharedClient] isNetworkReachable]) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    INatAPIFetchCompletionCountHandler handler = ^(NSArray *results, NSInteger count, NSError *error) {
        RLMRealm *realm = [RLMRealm defaultRealm];
        for (ExplorePost *post in results) {
            ExplorePostRealm *epr = [[ExplorePostRealm alloc] initWithMantleModel:post];
            [realm beginWriteTransaction];
            [realm addOrUpdateObject:epr];
            [realm commitWriteTransaction];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView reloadData];
                [weakSelf.tableView.infiniteScrollingView stopAnimating];
            });
        }
    };
    
    if (fetchNewPosts) {
        if (self.project) {
            [[self postsApi] newPostsForProjectId:self.project.projectId
                                          handler:handler];
        } else {
            [[self postsApi] newSitePostsHandler:handler];
        }
    } else {
        // get oldest known site post
        ExplorePostRealm *epr = self.posts.lastObject;
        
        if (self.project) {
            [[self postsApi] postsForProjectId:self.project.projectId
                                     olderThan:epr.postId
                                       handler:handler];
        } else {
            [[self postsApi] sitePostsOlderThan:epr.postId
                                        handler:handler];
        }
    }
}

@end
