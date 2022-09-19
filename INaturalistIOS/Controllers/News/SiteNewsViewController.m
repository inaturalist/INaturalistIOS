//
//  NewsViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 1/13/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <AFNetworking/UIImageView+AFNetworking.h>
#import <FontAwesomeKit/FAKIonIcons.h>
#import <NSString_stripHtml/NSString_stripHTML.h>
#import <SVPullToRefresh/SVPullToRefresh.h>
#import <Realm/Realm.h>

#import "SiteNewsViewController.h"
#import "UIColor+INaturalist.h"
#import "NewsItemViewController.h"
#import "NewsItemCell.h"
#import "UIColor+INaturalist.h"
#import "INaturalistAppDelegate.h"
#import "LoginController.h"
#import "INatReachability.h"
#import "PostsAPI.h"
#import "ExplorePost.h"
#import "NSDate+INaturalist.h"

static UIImage *briefcase;

@interface SiteNewsViewController () <NSFetchedResultsControllerDelegate, UITableViewDelegate, UITableViewDataSource>
@property IBOutlet UITableView *tableView;
@property NSArray *posts;
@property UIRefreshControl *refreshControl;
@end

@implementation SiteNewsViewController

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
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(loadNewNews) forControlEvents:UIControlEventValueChanged];
    
    // Add Refresh Control to Table View
    if (@available(iOS 10, *)) {
        self.tableView.refreshControl = self.refreshControl;
    }
    
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
    self.posts = [NSArray array];
    [self refresh];
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
        vc.post = (ExplorePost *)sender;
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
    
    ExplorePost *post = [self.posts objectAtIndex:indexPath.item];
    
    if (self.project) {
        cell.newsCategoryTitle.text = self.project.title;
        
        if (self.project.iconUrl) {
            [cell.newsCategoryImageView setImageWithURL:self.project.iconUrl];
        } else {
            cell.newsCategoryImageView.image = briefcase;
        }
    } else {
        cell.newsCategoryTitle.text = post.parentTitleText;
        if (post.parentIconUrl) {
            [cell.newsCategoryImageView setImageWithURL:post.parentIconUrl];
        } else {
            cell.newsCategoryImageView.image = briefcase;
        }
    }
    
    if (post.postCoverImageUrl) {
        [cell.postImageView setImageWithURL:post.postCoverImageUrl];
        [cell showPostImageView:YES];
    } else {
        [cell showPostImageView:NO];
    }
    
    cell.postTitle.text = post.postTitle;
    cell.postBody.text = post.postPlainTextExcerpt;
    
    cell.postedAt.text = [post.postPublishedAt inat_shortRelativeDateString];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ExplorePost *post = [self.posts objectAtIndex:indexPath.item];
        
    [self performSegueWithIdentifier:@"detail" sender:post];
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
    
    //returnType (^blockName)(parameterTypes) = ^returnType(parameters) {...};
    
    __weak typeof(self)weakSelf = self;
    INatAPIFetchCompletionCountHandler finished = ^void(NSArray *results, NSInteger count, NSError *error) {
        if (@available(iOS 10, *)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView.refreshControl endRefreshing];
            });
        }


        // extract excerpt and post image url
        for (ExplorePost *post in results) {
            [post computeProperties];
        }
        // merge the new values in
        NSArray *allResults = [[weakSelf posts] arrayByAddingObjectsFromArray:results];
        // make them unique
        NSSet *allResultsSet = [NSSet setWithArray:allResults];
        // sort them
        weakSelf.posts = [[allResultsSet allObjects] sortedArrayUsingDescriptors:[self postSortDescriptors]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf.tableView reloadData];
        });
    };
    
    if (self.project) {
        [[self postsApi] postsForProjectId:self.project.projectId handler:finished];
    } else {
        if (self.posts.count > 0) {
            ExplorePost *firstPost = [self.posts firstObject];
            [[self postsApi] userPostsNewerThanPost:firstPost.postId handler:finished];
        } else {
            [[self postsApi] userPosts:finished];
        }
    }
}

- (NSArray *)postSortDescriptors {
    return @[
        [NSSortDescriptor sortDescriptorWithKey:@"postId" ascending:NO],
    ];
}

- (void)loadOldNews {
    // silently do nothing if we're offline
    if (![[INatReachability sharedClient] isNetworkReachable]) {
        return;
    }
    
    
    if (self.project) {
        // no old news for projects, sorry
        // api doesn't support older_than here
    } else {
        ExplorePost *lastPost = [self.posts lastObject];
        
        __weak typeof(self)weakSelf = self;
        [[self postsApi] userPostsOlderThanPost:lastPost.postId handler:^(NSArray *results, NSInteger count, NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView.infiniteScrollingView stopAnimating];
            });

            // extract excerpt and post image url
            for (ExplorePost *post in results) {
                [post computeProperties];
            }
            // merge the new values in
            NSArray *allResults = [[weakSelf posts] arrayByAddingObjectsFromArray:results];
            // make them unique
            NSSet *allResultsSet = [NSSet setWithArray:allResults];
            // sort them
            weakSelf.posts = [[allResultsSet allObjects] sortedArrayUsingDescriptors:[self postSortDescriptors]];

            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.tableView reloadData];
            });
        }];
    }
}

@end
