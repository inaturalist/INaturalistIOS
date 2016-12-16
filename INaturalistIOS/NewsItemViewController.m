//
//  NewsItemViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 1/15/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <YLMoment/YLMoment.h>
#import <ARSafariActivity/ARSafariActivity.h>

#import "NewsItemViewController.h"
#import "NewsItem.h"
#import "User.h"
#import "Analytics.h"

@interface NewsItemViewController ()

@end

@implementation NewsItemViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = self.newsItem.parentTitleText;
    
    if (self.newsItem.urlForNewsItem) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                               target:self
                                                                                               action:@selector(share:)];
    }
    
    [self loadPostBodyIntoWebView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)share:(UIBarButtonItem *)button {
    
    [[Analytics sharedClient] event:kAnalyticsEventNewsShareStarted];
    
    
    ARSafariActivity *safariActivity = [[ARSafariActivity alloc] init];
    
    UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[self.newsItem.urlForNewsItem]
                                                                           applicationActivities:@[safariActivity]];
    activity.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
        if (completed) {
            [[Analytics sharedClient] event:kAnalyticsEventNewsShareFinished
                             withProperties:@{ @"destination": activityType }];
        } else {
            [[Analytics sharedClient] event:kAnalyticsEventNewsShareCancelled];
        }
    };
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        activity.modalPresentationStyle = UIModalPresentationPopover;
        activity.popoverPresentationController.barButtonItem = button;
    }
    [self presentViewController:activity animated:YES completion:nil];

}

- (void)loadPostBodyIntoWebView {
    NSString *html = @"<head><meta name=\"viewport\" content=\"width=device-width; initial-scale=1.0; maximum-scale=1.0; user-scalable=0;\" /></head>";

    html = [html stringByAppendingString:@"<body style=\"font-family: -apple-system, Helvetica, Arial, sans-serif; font-size: 17; \" ><style>div {max-width: 100%%; font-family=-apple-system, Helvetica, Arial, sans-serif; } figure { padding: 0; margin: 0; } img.user { padding-top: 0; padding-bottom: 0; border: 1px solid #C8C7CC; width: 20; height: 20; border-radius: 50%%; margin-right: 4; margin-left: 7; vertical-align: middle; } img { padding-top: 4; padding-bottom: 4; max-width: 100%%; } p {font-family: -apple-system, Helvetica, Arial, sans-serif; } div.post { padding-left: 0; padding-right: 0; margin-left: 15; margin-right: 15; }</style><div class=\"post\">"];

    NSString *title = self.newsItem.postTitle ?: NSLocalizedString(@"Untitled Post", nil);
    html = [html stringByAppendingString:[NSString stringWithFormat:@"<p style=\"font-size: 24; \">%@</p>", title]];
    
    NSString *postedBy = NSLocalizedString(@"Posted by", @"label for a news post author");
    NSString *authorIconURL = self.newsItem.authorIconUrl;
    html = [html stringByAppendingString:[NSString stringWithFormat:@"<p style=\"font-size: 14; color: #686868;\">%@:<img class=\"user\" src=%@ />", postedBy, authorIconURL]];
    NSString *author = self.newsItem.authorLogin ?: NSLocalizedString(@"Unknown author", nil);
    NSString *publishedAt = [[YLMoment momentWithDate:self.newsItem.postPublishedAt] fromNowWithSuffix:NO];
    html = [html stringByAppendingString:[NSString stringWithFormat:@"%@  •  %@</p>", author, publishedAt]];

    html = [html stringByAppendingString:self.newsItem.postBody];
    html = [html stringByAppendingString:@"</div></body>"];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://inat-project-post/%lld", self.newsItem.recordID.longLongValue]];
    
    [self.postBodyWebView loadHTMLString:html
                                 baseURL:url];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self loadPostBodyIntoWebView];
    } completion:nil];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        
        [[Analytics sharedClient] event:kAnalyticsEventNewsTapLink
                         withProperties:@{
                                          @"ParentType": [self.newsItem parentTypeString],
                                          @"ParentName": [self.newsItem parentTitleText],
                                          @"ArticleTitle": [self.newsItem postTitle],
                                          @"Link": request.URL.absoluteString,
                                          }];

        // open links taps in Safari
        [[UIApplication sharedApplication] openURL:request.URL];
        return NO;
    }
    
    return YES;
}

@end
