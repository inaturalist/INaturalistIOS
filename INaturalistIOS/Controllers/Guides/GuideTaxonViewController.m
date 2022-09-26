//
//  GuideTaxonViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 9/16/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import <MHVideoPhotoGallery/MHGalleryController.h>
#import <MHVideoPhotoGallery/MHGallery.h>
#import <MHVideoPhotoGallery/MHTransitionDismissMHGallery.h>
#import <BlocksKit/BlocksKit+UIKit.h>

#import "GuideTaxonViewController.h"
#import "Observation.h"
#import "RXMLElement+Helpers.h"
#import "GuideImageXML.h"
#import "Taxon.h"
#import "iNaturalist-Swift.h"
#import "ExploreTaxonRealm.h"

static const int WebViewTag = 1;

@interface GuideTaxonViewController ()
@property (strong, nonatomic) IBOutlet UIWebView *webView;
- (void)showAssetByURL:(NSString *)url;
@end

@implementation GuideTaxonViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.webView.delegate = self;
    if (self.guideTaxon.displayName) {
        self.title = self.guideTaxon.displayName;
    } else {
        self.title = self.guideTaxon.name;
    }
    NSString *xmlString = [self.guideTaxon.xml xmlString];
    BOOL local = [[NSFileManager defaultManager] fileExistsAtPath:[self.guideTaxon.guide.dirPath stringByAppendingPathComponent:@"files"]];
    if (xmlString && [xmlString rangeOfString:@"xsl"].location == NSNotFound) {
        NSString *xslPath;
        if (local) {
            xslPath = [[NSBundle mainBundle] pathForResource:@"guide_taxon-local" ofType:@"xsl"];
        } else {
            xslPath = [[NSBundle mainBundle] pathForResource:@"guide_taxon-remote" ofType:@"xsl"];
        }
        NSString *header = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<?xml-stylesheet type=\"text/xsl\" href=\"%@\"?>\n<INatGuide xmlns:dc=\"http://purl.org/dc/elements/1.1/\" xmlns:dcterms=\"http://purl.org/dc/terms/\" xmlns:eol=\"http://www.eol.org/transfer/content/1.0\">", xslPath];
        xmlString = [[header stringByAppendingString:xmlString] stringByAppendingString:@"</INatGuide>"];
    }
    NSURL *baseURL = [NSURL fileURLWithPath:self.guideTaxon.guide.dirPath];
    [self.webView loadData:[xmlString dataUsingEncoding:NSUTF8StringEncoding]
                  MIMEType:@"text/xml"
          textEncodingName:@"utf-8"
                   baseURL:baseURL];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.navigationController setToolbarHidden:YES animated:animated];
}

- (IBAction)clickedObserve:(id)sender {
    // we're working from serialized taxon objects (GuideTaxonXML) but this API wants
    // regular Taxon objects.
    INatTabBarController *tabBar = (INatTabBarController *)self.tabBarController;
    
    if (self.guideTaxon.taxonID && self.guideTaxon.taxonID.length > 0) {
        // try to get an ExploreTaxonRealm object out for it
        NSInteger taxonId = [self.guideTaxon.taxonID integerValue];
        ExploreTaxonRealm *etr = [ExploreTaxonRealm objectForPrimaryKey:@(taxonId)];        
        [tabBar triggerNewObservationFlowForTaxon:etr];
    } else {
        [tabBar triggerNewObservationFlowForTaxon:nil];
    }
}

# pragma mark - UIWebViewDelegate
// http://engineering.tumblr.com/post/32329287335/javascript-native-bridge-for-ioss-uiwebview
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *urlString = [[request URL] absoluteString];
    if ([urlString hasPrefix:@"js:"]) {
        // do nothing
    } else if ([urlString hasPrefix:@"file:"] && [urlString rangeOfString:@"files/"].location != NSNotFound) {
        [self showAssetByURL:urlString];
    } else if ([urlString hasPrefix:@"http:"] || [urlString hasPrefix:@"https:"]) {
        if ([self.guideTaxon.xml atXPath:[NSString stringWithFormat:@"descendant::*[text()='%@']", urlString]]) {
            [self showAssetByURL:urlString];
        } else if (navigationType == UIWebViewNavigationTypeLinkClicked) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                           message:nil
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil)
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Open link in Safari", nil)
                                                      style:UIAlertActionStyleDefault
                                                    handler:^(UIAlertAction * _Nonnull action) {
                
                if ([UIApplication.sharedApplication canOpenURL:request.URL]) {
                    [UIApplication.sharedApplication openURL:request.URL
                                                     options:@{}
                                           completionHandler:nil];
                    
                }
            }]];
            
            [self.tabBarController presentViewController:alert animated:YES completion:nil];
        }
    } else if ([urlString hasPrefix:@"file:"]) {
        return YES;
    }
    return NO;
}


# pragma mark - GuideTaxonViewController
- (void)showAssetByURL:(NSString *)url
{    
    NSArray *galleryData = [self.guideTaxon.guidePhotos bk_map:^id(GuideImageXML *image) {
        if (image.mediumPhotoUrl.host) {
            return [MHGalleryItem itemWithURL:image.mediumPhotoUrl.absoluteString
                                  galleryType:MHGalleryTypeImage];
        } else {
            return [MHGalleryItem itemWithImage:[UIImage imageWithContentsOfFile:image.mediumPhotoUrl.path]];
        }
    }];
    
    MHUICustomization *customization = [[MHUICustomization alloc] init];
    customization.showOverView = NO;
    customization.showMHShareViewInsteadOfActivityViewController = NO;
    customization.hideShare = YES;
    customization.useCustomBackButtonImageOnImageViewer = NO;
    
    MHGalleryController *gallery = [MHGalleryController galleryWithPresentationStyle:MHGalleryViewModeImageViewerNavigationBarShown];
    gallery.galleryItems = galleryData;
    gallery.presentationIndex = 0;
    gallery.UICustomization = customization;
    
    __weak MHGalleryController *blockGallery = gallery;
    
    gallery.finishedCallback = ^(NSInteger currentIndex, UIImage *image, MHTransitionDismissMHGallery *interactiveTransition, MHGalleryViewMode viewMode) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [blockGallery dismissViewControllerAnimated:YES completion:nil];
        });
    };
    
    [self presentMHGalleryController:gallery animated:YES completion:nil];

}

@end
