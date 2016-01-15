//
//  NewsItemViewController.h
//  iNaturalist
//
//  Created by Alex Shepard on 1/15/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ProjectPost;

@interface NewsItemViewController : UIViewController <UIWebViewDelegate>

@property IBOutlet UILabel *postTitle;
@property IBOutlet UILabel *postAuthor;
@property IBOutlet UILabel *postPublishedAt;
@property IBOutlet UIWebView *postBodyWebView;

@property ProjectPost *post;

@end
