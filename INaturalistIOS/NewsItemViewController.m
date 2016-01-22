//
//  NewsItemViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 1/15/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "NewsItemViewController.h"
#import "ProjectPost.h"
#import "User.h"
#import "Analytics.h"

@interface NewsItemViewController ()

@end

@implementation NewsItemViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *title = self.post.title ?: NSLocalizedString(@"Untitled Post", nil);
    NSString *author = self.post.author.login ?: NSLocalizedString(@"Unknown author", nil);
    NSString *authorIconURL = self.post.author.userIconURL;

    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateStyle = NSDateFormatterShortStyle;
    dateFormatter.timeStyle = NSDateFormatterNoStyle;
    dateFormatter.doesRelativeDateFormatting = YES;
    
    NSString *date = [dateFormatter stringFromDate:self.post.publishedAt] ?: NSLocalizedString(@"Uknown date", nil);
    
    NSString *html = @"<head><meta name=\"viewport\" content=\"width=device-width; initial-scale=1.0; maximum-scale=1.0; user-scalable=0;\" /></head>";

    html = [html stringByAppendingString:@"<body style=\"font-family: -apple-system, Helvetica, Arial, sans-serif; font-size: 17; \" ><style>div {max-width: 100%%; font-family=-apple-system, Helvetica, Arial, sans-serif; } figure { padding: 0; margin: 0; } img.user {width: 25; height: 25; -webkit-border-radius: 50%%; margin-right: 10; } img { width: 100%%; max-width: 100%%; } p {font-family: -apple-system, Helvetica, Arial, sans-serif; }</style><div>"];

    html = [html stringByAppendingString:[NSString stringWithFormat:@"<p style=\"font-size: 24; \">%@</p>", title]];
    html = [html stringByAppendingString:[NSString stringWithFormat:@"<img align=\"left\" class=\"user\" src=%@ />", authorIconURL]];
    html = [html stringByAppendingString:[NSString stringWithFormat:@"<p style=\"font-size: 17; \">%@ • %@</p>", author, date]];

    html = [html stringByAppendingString:self.post.body];
    html = [html stringByAppendingString:@"</div></body>"];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://inat-project-post/%lld", self.post.recordID.longLongValue]];
    
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
