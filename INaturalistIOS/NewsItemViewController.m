//
//  NewsItemViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 1/15/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <YLMoment/YLMoment.h>

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
    
    [self loadPostBodyIntoWebView];
}

- (void)loadPostBodyIntoWebView {
    NSString *html = @"<head><meta name=\"viewport\" content=\"width=device-width; initial-scale=1.0; maximum-scale=1.0; user-scalable=0;\" /></head>";

    html = [html stringByAppendingString:@"<body style=\"font-family: -apple-system, Helvetica, Arial, sans-serif; font-size: 17; \" ><style>div {max-width: 100%%; font-family=-apple-system, Helvetica, Arial, sans-serif; } figure { padding: 0; margin: 0; } img.user { border: 1px solid #C8C7CC; width: 20; height: 20; -webkit-border-radius: 50%%; margin-right: 4; margin-left: 7; vertical-align: middle; } img { padding-top: 4; padding-bottom: 4; max-width: 100%%; } p {font-family: -apple-system, Helvetica, Arial, sans-serif; } div.post { padding-left: 0; padding-right: 0; margin-left: 15; margin-right: 15; }</style><div class=\"post\">"];

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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [[Analytics sharedClient] timedEvent:kAnalyticsEventNavigateNewsDetail];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[Analytics sharedClient] endTimedEvent:kAnalyticsEventNavigateNewsDetail];
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
        // open links taps in Safari
        [[UIApplication sharedApplication] openURL:request.URL];
        return NO;
    }
    
    return YES;
}

@end
