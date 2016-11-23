//
//  INatWebController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/27/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "INatWebController.h"

@interface INatWebController () <UIWebViewDelegate> {
    NSURL *_url;
    
    UIActivityIndicatorView *spinner;
}
@end

@implementation INatWebController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.webView.delegate = self;
    self.webView.scalesPageToFit = YES;
    
    [self.view addSubview:self.webView];
    
    spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.hidden = YES;
    [spinner setHidesWhenStopped:YES];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:spinner];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self loadURL:self.url forWebView:self.webView];
}

#pragma mark - webview helper

- (void)loadURL:(NSURL *)url forWebView:(UIWebView *)web {
    if (url) {
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        if (web && web.superview) {
            [web loadRequest:request];
        }
    }
}

#pragma mark - setter/getter

- (void)setUrl:(NSURL *)url {
    if ([_url isEqual:url])
        return;
    
    _url = url;
    
    [self loadURL:url forWebView:self.webView];
}

- (NSURL *)url {
    return _url;
}

#pragma mark webview delegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (self.delegate) {
        return [self.delegate webView:webView shouldLoadRequest:request];
    } else {
        return YES;
    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    spinner.hidden = NO;
    [spinner startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [spinner stopAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if ([error.domain isEqualToString:@"WebKitErrorDomain"] && error.code == 102) {
        return;
    }
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Unable to load page", @"Title for error")
                                                                   message:error.localizedDescription
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
