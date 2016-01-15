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

    self.postTitle.text = self.post.title;
    self.postAuthor.text = self.post.author.login;
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateStyle = NSDateFormatterShortStyle;
    dateFormatter.timeStyle = NSDateFormatterNoStyle;
    dateFormatter.doesRelativeDateFormatting = YES;
    
    self.postPublishedAt.text = [dateFormatter stringFromDate:self.post.publishedAt];
    
    CGFloat width = self.view.bounds.size.width - 40;
    
    NSString *html = @"<head><meta name=\"viewport\" content=\"width=device-width; initial-scale=1.0; maximum-scale=1.0; user-scalable=0;\" /></head>";

    html = [html stringByAppendingString:[NSString stringWithFormat:@"<body><style>div {max-width: %fpx;}</style><div>", width]];

    html = [html stringByAppendingString:self.post.body];
    html = [html stringByAppendingString:@"</div></body>"];
    
    [self.postBodyWebView loadHTMLString:html baseURL:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
- (void)webViewDidFinishLoad:(UIWebView *)theWebView
{
    CGSize contentSize = theWebView.scrollView.contentSize;
    CGSize viewSize = theWebView.bounds.size;
    
    float rw = viewSize.width / contentSize.width;
    
    theWebView.scrollView.minimumZoomScale = rw;
    theWebView.scrollView.maximumZoomScale = rw;
    theWebView.scrollView.zoomScale = rw;
}
 */

@end
