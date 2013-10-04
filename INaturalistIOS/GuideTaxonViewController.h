//
//  GuideTaxonViewController.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 9/16/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RXMLElement.h"
#import "ObservationDetailViewController.h"
#import "GuideTaxonXML.h"

@interface GuideTaxonViewController : UIViewController <ObservationDetailViewControllerDelegate, UIWebViewDelegate>
@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) GuideTaxonXML *guideTaxon;
- (IBAction)clickedObserve:(id)sender;
- (void)showAssetByURL:(NSString *)url;
@end
