//
//  NewsItemViewController.h
//  iNaturalist
//
//  Created by Alex Shepard on 1/15/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ExplorePostRealm;

@interface NewsItemViewController : UIViewController <UIWebViewDelegate>

@property IBOutlet UIWebView *postBodyWebView;

@property ExplorePostRealm *post;

@end
