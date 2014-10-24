//
//  ExploreTaxonDetailsViewController.m
//  Explore Prototype
//
//  Created by Alex Shepard on 10/13/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <RestKit/RestKit.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <FlurrySDK/Flurry.h>

#import "ExploreTaxonDetailsViewController.h"
#import "ExploreMappingProvider.h"
#import "ExploreTaxon.h"
#import "UIColor+ExploreColors.h"

@interface ExploreTaxonDetailsViewController () {
    NSInteger _taxonId;
    
    UIImageView *taxaImageView;
    UIWebView *taxaWebView;
}
@end

@implementation ExploreTaxonDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    taxaImageView = ({
        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectZero];
        iv.translatesAutoresizingMaskIntoConstraints = NO;
        
        iv.contentMode = UIViewContentModeScaleAspectFit;
        iv.clipsToBounds = YES;
        
        iv;
    });
    [self.view addSubview:taxaImageView];
    
    taxaWebView = ({
        UIWebView *wv = [[UIWebView alloc] initWithFrame:CGRectZero];
        wv.translatesAutoresizingMaskIntoConstraints = NO;
                
        wv;
    });
    [self.view addSubview:taxaWebView];
    
    NSDictionary *views = @{
                            @"taxaImageView": taxaImageView,
                            @"taxaWebView": taxaWebView,
                            @"topLayoutGuide": self.topLayoutGuide,
                            @"bottomLayoutGuide": self.bottomLayoutGuide,
                            };
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[taxaImageView]-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[taxaWebView]-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-[topLayoutGuide]-[taxaImageView(>=200)]-[taxaWebView(>=200)]-[bottomLayoutGuide]-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];


    
    if (self.taxonId != 0)
        [self updateUIForTaxaId:self.taxonId];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [Flurry logEvent:@"Navigate - Explore Taxon Details" timed:YES];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [Flurry endTimedEvent:@"Navigate - Explore Taxon Details" withParameters:nil];
}

- (NSInteger)taxonId {
    return _taxonId;
}

- (void)setTaxonId:(NSInteger)taxaId {
    _taxonId = taxaId;
    
    [self updateUIForTaxaId:taxaId];
}

- (void)updateUIForTaxaId:(NSInteger)taxaId {
    // fetch taxa via restkit
    
    /*
     RESTKIT 0.20
     
    NSIndexSet *statusCodeSet = RKStatusCodeIndexSetForClass(RKStatusCodeClassSuccessful);
    RKMapping *mapping = [ExploreMappingProvider taxaMapping];
    
    NSString *baseURL = [NSString stringWithFormat:@"http://www.inaturalist.org/taxa/%ld.json", (long)taxaId];
    NSString *pathPattern = [NSString stringWithFormat:@"/taxa/%ld.json", (long)taxaId];
    
    RKResponseDescriptor *responseDescriptor = [RKResponseDescriptor responseDescriptorWithMapping:mapping
                                                                                            method:RKRequestMethodGET
                                                                                       pathPattern:pathPattern
                                                                                           keyPath:@""
                                                                                       statusCodes:statusCodeSet];
    
    NSURL *url = [NSURL URLWithString:baseURL];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    RKObjectRequestOperation *operation = [[RKObjectRequestOperation alloc] initWithRequest:request
                                                                        responseDescriptors:@[responseDescriptor]];
    [operation setCompletionBlockWithSuccess:^(RKObjectRequestOperation *operation, RKMappingResult *mappingResult) {
        if (mappingResult.count == 1) {
            ExploreTaxa *taxa = (ExploreTaxa *)mappingResult.firstObject;
            
            [taxaImageView sd_setImageWithURL:[NSURL URLWithString:taxa.taxaPhotoUrl]
                             placeholderImage:nil
                                    completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                        [taxaImageView setNeedsDisplay];
                                    }];
            
            [taxaWebView loadHTMLString:taxa.taxaWebContent baseURL:url];
            [taxaWebView setNeedsLayout];
            [taxaWebView setNeedsDisplay];
            
            [self.view setNeedsLayout];
        }
    } failure:^(RKObjectRequestOperation *operation, NSError *error) {
        NSLog(@"error: %@", error.localizedDescription);
    }];
    
    [operation start];
     */

}

@end
