//
//  GuideTaxonViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 9/16/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import "GuideTaxonViewController.h"
#import "Observation.h"
#import "ObservationDetailViewController.h"
#import "RXMLElement+Helpers.h"

@interface GuideTaxonViewController ()

@end

static const int WebViewTag = 1;

@implementation GuideTaxonViewController
@synthesize webView = _webView;
@synthesize xml = _xml;
@synthesize xmlString = _xmlString;
@synthesize basePath = _basePath;
@synthesize local = _local;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (!self.webView) {
        self.webView = (UIWebView *)[self.view viewWithTag:WebViewTag];
    }
    if (self.xmlString && [self.xmlString rangeOfString:@"xsl"].location == NSNotFound) {
        NSString *xslPath;
        if (self.local) {
            xslPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"guide_taxon-local.xsl"];
        } else {
            xslPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"guide_taxon-remote.xsl"];
        }
        NSString *header = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<?xml-stylesheet type=\"text/xsl\" href=\"%@\"?>\n<INatGuide xmlns:dc=\"http://purl.org/dc/elements/1.1/\">", xslPath];
        self.xmlString = [[header stringByAppendingString:self.xmlString] stringByAppendingString:@"</INatGuide>"];
    }
    if (!self.xml) {
        self.xml = [[RXMLElement alloc] initFromXMLString:self.xmlString encoding:NSUTF8StringEncoding];
    }
    NSURL *baseURL = [NSURL fileURLWithPath:self.basePath];
    [self.webView loadData:[self.xmlString dataUsingEncoding:NSUTF8StringEncoding]
                  MIMEType:@"text/xml"
          textEncodingName:@"utf-8"
                   baseURL:baseURL];
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.navigationController setToolbarHidden:YES animated:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [self setWebView:nil];
    [super viewDidUnload];
}
- (IBAction)clickedObserve:(id)sender {
    [self performSegueWithIdentifier:@"GuideTaxonObserveSegue" sender:sender];
}
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"GuideTaxonObserveSegue"]) {
        ObservationDetailViewController *vc = [segue destinationViewController];
        [vc setDelegate:self];
        Observation *o = [Observation object];
        o.localObservedOn = [NSDate date];
        o.speciesGuess = [[self.xml atXPath:@"//GuideTaxon/name"] text];
        [vc setObservation:o];
    }
}
@end
