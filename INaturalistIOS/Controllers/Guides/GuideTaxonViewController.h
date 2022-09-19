//
//  GuideTaxonViewController.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 9/16/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RXMLElement.h"
#import "GuideTaxonXML.h"

@interface GuideTaxonViewController : UIViewController <UIWebViewDelegate>
{
    NSURL *lastURL;
}
@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) GuideTaxonXML *guideTaxon;

// position of this controller in context if contained in some kind of collection
@property (assign, nonatomic) NSInteger localPosition;
- (IBAction)clickedObserve:(id)sender;
- (void)showAssetByURL:(NSString *)url;
@end
