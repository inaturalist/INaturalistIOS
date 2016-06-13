//
//  GooglePlusAuthViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/20/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "GooglePlusAuthViewController.h"

@implementation GooglePlusAuthViewController

+ (NSString *)authNibName {
    // subclasses may override this to specify a custom nib name
    return @"GooglePlusAuthViewController";
}

+ (NSBundle *)authNibBundle {
    // subclasses may override this to specify a custom nib bundle
    return nil;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    // the service login page is sized correctly
    // but the authorization page doesn't scale correctly in the viewport on phones
    if (([webView.request.URL.absoluteString rangeOfString:@"https://accounts.google.com/ServiceLogin"].location == NSNotFound) &&
        [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        
        [webView stringByEvaluatingJavaScriptFromString:@"document.body.style.zoom = 0.5;"];
    }
    
    // allow our superclass to setup the necessary hooks to redirect back into the app after login
    [super webViewDidFinishLoad:webView];
}

@end
