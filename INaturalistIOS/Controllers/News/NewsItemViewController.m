//
//  NewsItemViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 1/15/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <ARSafariActivity/ARSafariActivity.h>

#import "NewsItemViewController.h"
#import "ExplorePost.h"
#import "NSDate+INaturalist.h"

@interface NewsItemViewController () <WKNavigationDelegate>
@property IBOutlet WKWebView *postBodyWebView;
@end

@implementation NewsItemViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = self.post.parentTitleText;
    
    if (self.post.urlForNewsItem) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                               target:self
                                                                                               action:@selector(share:)];
    }
    
    self.postBodyWebView.navigationDelegate = self;
    [self loadPostBodyIntoWebView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)share:(UIBarButtonItem *)button {
    ARSafariActivity *safariActivity = [[ARSafariActivity alloc] init];
    
    UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:@[self.post.urlForNewsItem]
                                                                           applicationActivities:@[safariActivity]];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        activity.modalPresentationStyle = UIModalPresentationPopover;
        activity.popoverPresentationController.barButtonItem = button;
    }
    [self presentViewController:activity animated:YES completion:nil];

}

- (void)loadPostBodyIntoWebView {
    NSString *html = @"<head><meta name=\"viewport\" content=\"width=device-width; initial-scale=1.0; maximum-scale=1.0; user-scalable=0;\" /></head>";

    html = [html stringByAppendingString:@"<body style=\"font-family: -apple-system, Helvetica, Arial, sans-serif; font-size: 17; \" ><style>div {max-width: 100%%; font-family=-apple-system, Helvetica, Arial, sans-serif; } figure { padding: 0; margin: 0; } img.user { padding-top: 0; padding-bottom: 0; border: 1px solid #C8C7CC; width: 20; height: 20; border-radius: 50%%; margin-right: 4; margin-left: 7; vertical-align: middle; } img { padding-top: 4; padding-bottom: 4; max-width: 100%%; } p {font-family: -apple-system, Helvetica, Arial, sans-serif; } div.post { padding-left: 0; padding-right: 0; margin-left: 15; margin-right: 15; }</style><div class=\"post\">"];

    NSString *title = self.post.postTitle ?: NSLocalizedString(@"Untitled Post", @"Title displayed for a journal post when the post has no title" );
    html = [html stringByAppendingString:[NSString stringWithFormat:@"<p style=\"font-size: 24; \">%@</p>", title]];
    
    NSString *postedBy = NSLocalizedString(@"Posted by", @"label for a news post author");
    NSString *authorIconURL = self.post.authorIconUrl;
    html = [html stringByAppendingString:[NSString stringWithFormat:@"<p style=\"font-size: 14; color: #686868;\">%@:<img class=\"user\" src=%@ />", postedBy, authorIconURL]];
    NSString *author = self.post.authorLogin ?: NSLocalizedString(@"Unknown author", @"Text shown in place of a post author when a post has no known author");
    NSString *publishedAt = [self.post.postPublishedAt inat_shortRelativeDateString];
    html = [html stringByAppendingString:[NSString stringWithFormat:@"%@  •  %@</p>", author, publishedAt]];

    html = [html stringByAppendingString:self.post.postBody];
    html = [html stringByAppendingString:@"</div></body>"];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://inat-project-post/%ld", (long)self.post.postId]];
    
    [self.postBodyWebView loadHTMLString:html baseURL:url];
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
#pragma mark - WKUIDelegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        decisionHandler(WKNavigationActionPolicyCancel);
        
        if ([UIApplication.sharedApplication canOpenURL:navigationAction.request.URL]) {
            [UIApplication.sharedApplication openURL:navigationAction.request.URL
                                             options:@{}
                                   completionHandler:nil];
        }
    } else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

@end
