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

@interface NewsItemViewController ()

@end

@implementation NewsItemViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString *title = self.post.title ?: NSLocalizedString(@"Untitled Post", nil);
    NSString *author = self.post.author.login ?: NSLocalizedString(@"Unknown author", nil);

    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateStyle = NSDateFormatterShortStyle;
    dateFormatter.timeStyle = NSDateFormatterNoStyle;
    dateFormatter.doesRelativeDateFormatting = YES;
    
    NSString *date = [dateFormatter stringFromDate:self.post.publishedAt] ?: NSLocalizedString(@"Uknown date", nil);
    
    CGFloat width = self.view.bounds.size.width - 10;
    
    NSString *html = @"<head><meta name=\"viewport\" content=\"width=device-width; initial-scale=1.0; maximum-scale=1.0; user-scalable=0;\" /></head>";

    html = [html stringByAppendingString:[NSString stringWithFormat:@"<body style=\"font-family: -apple-system; sans-serif\"><style>div {max-width: %fpx; font-family=-apple-system, Helvetica, Arial, sans-serif;} img {width: 100%%; max-width: 100%%;}</style><div>", width]];

    
    html = [html stringByAppendingString:[NSString stringWithFormat:@"<h3>%@</h3><h4>%@ • %@</h4>", title, author, date]];

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
