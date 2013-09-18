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

@interface GuideTaxonViewController : UIViewController <ObservationDetailViewControllerDelegate>
@property (strong, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) RXMLElement *xml;
- (IBAction)clickedObserve:(id)sender;
@property (strong, nonatomic) NSString *xmlString;
@end
