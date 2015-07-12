//
//  INatWebController.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/27/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol INatWebControllerDelegate
- (BOOL)webView:(UIWebView *)webView shouldLoadRequest:(NSURLRequest *)request;
@end

@interface INatWebController : UIViewController

@property NSURL *url;
@property UIWebView *webView;
@property (weak) id <INatWebControllerDelegate> delegate;

@end
