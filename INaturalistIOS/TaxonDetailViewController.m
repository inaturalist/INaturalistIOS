//
//  TaxonDetailViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/23/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>
#import <SDWebImage/SDWebImageManager.h>
#import <objc/runtime.h>

#import "TaxonDetailViewController.h"
#import "Taxon.h"
#import "Observation.h"
#import "TaxonPhoto.h"
#import "ImageStore.h"
#import "ObservationDetailViewController.h"
#import "UIColor+INaturalist.h"
#import "Analytics.h"
#import "INatUITabBarController.h"
#import "NSURL+INaturalist.h"
#import "TaxonPhotoCell.h"
#import "TaxonSummaryCell.h"
#import "RoundedButtonCell.h"

static char SUMMARY_ASSOCIATED_KEY;

@interface Taxon (Summary)
- (NSAttributedString *)attributedBody;
@end

@implementation Taxon (Summary)
// extracting attributed strings from HTML is expensive
// stash the attributed summary in an associated object on the taxon itself
- (NSAttributedString *)attributedBody {
    NSAttributedString *_attributedBody = objc_getAssociatedObject(self, &SUMMARY_ASSOCIATED_KEY);
    if (_attributedBody) {
        return _attributedBody;
    } else {
        NSMutableAttributedString *attributedBody = [[NSMutableAttributedString alloc] init];
 
        if ([self.name isEqualToString:self.defaultName] || self.defaultName == nil || [self.defaultName isEqualToString:@""]) {
            // no common name, so only show scientific name in the main label
            NSString *name;
            NSDictionary *attributes;
            if (self.isGenusOrLower) {
                name = [NSString stringWithFormat:@"%@\n\n", self.name];
                attributes = @{
                               NSFontAttributeName: [UIFont italicSystemFontOfSize:24],
                               };
            } else {
                name = [NSString stringWithFormat:@"%@ %@\n\n", [self.rank capitalizedString], self.name];
                attributes = @{
                               NSFontAttributeName: [UIFont systemFontOfSize:24],
                               };
            }
            [attributedBody appendAttributedString:[[NSAttributedString alloc] initWithString:name
                                                                                   attributes:attributes]];
        } else {
            // show both common & scientfic names
            NSString *commonName = [NSString stringWithFormat:@"%@\n", self.defaultName];

            NSDictionary *commonNameAttrs = @{
                                              NSFontAttributeName:[UIFont systemFontOfSize:24],
                                              };
            
            [attributedBody appendAttributedString:[[NSAttributedString alloc] initWithString:commonName
                                                                                   attributes:commonNameAttrs]];
            
            NSString *sciName;
            NSDictionary *sciNameAttrs;

            
            if (self.isGenusOrLower) {
                sciName = [NSString stringWithFormat:@"%@\n\n", self.name];
                sciNameAttrs = @{
                                 NSFontAttributeName: [UIFont italicSystemFontOfSize:16],
                                 };
            } else {
                sciName = [NSString stringWithFormat:@"%@ %@\n\n", [self.rank capitalizedString], self.name];
                sciNameAttrs = @{
                                 NSFontAttributeName: [UIFont systemFontOfSize:16],
                                 };
            }
            
            [attributedBody appendAttributedString:[[NSAttributedString alloc] initWithString:sciName
                                                                                   attributes:sciNameAttrs]];

        }
        
        if (self.wikipediaSummary && self.wikipediaSummary.length > 0 ) {
            NSData *sumData = [self.wikipediaSummary dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *sumOpts = @{
                                      NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                      NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding),
                                      };
            NSMutableAttributedString *summary = [[NSMutableAttributedString alloc] initWithData:sumData
                                                                                         options:sumOpts
                                                                              documentAttributes:nil
                                                                                           error:nil];
            [summary setAttributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:16] }
                             range:NSMakeRange(0, [summary length])];
            
            [attributedBody appendAttributedString:summary];
        } else {
            NSString *placeHolderText = NSLocalizedString(@"We have no information about this taxon.", nil);
            NSDictionary *placeholderAttrs = @{
                                               NSFontAttributeName: [UIFont systemFontOfSize:16],
                                               };
            NSAttributedString *placeHolder = [[NSAttributedString alloc] initWithString:placeHolderText
                                                                              attributes:placeholderAttrs];
            [attributedBody appendAttributedString:placeHolder];
        }
        
        objc_setAssociatedObject(self, &SUMMARY_ASSOCIATED_KEY, attributedBody, OBJC_ASSOCIATION_COPY);
        return attributedBody;
    }
}

@end

@interface TaxonDetailViewController ()
@property Taxon *fullTaxon;
@end

@implementation TaxonDetailViewController

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UIControl targets

- (void)creditsTapped:(UIButton *)sender {
    TaxonPhoto *tp = [self.fullTaxon.taxonPhotos firstObject];
    NSURL *url = [NSURL URLWithString:[tp nativePageURL]];
    [[UIApplication sharedApplication] openURL:url];
}

- (void)wikipediaTapped:(UIButton *)sender {
    [[UIApplication sharedApplication] openURL:[self.fullTaxon wikipediaUrl]];
}

- (IBAction)clickedActionButton:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(taxonDetailViewControllerClickedActionForTaxonId:)]) {
        [self.delegate taxonDetailViewControllerClickedActionForTaxonId:[self.taxon taxonId]];
    } else {
        // be defensive
        if (self.tabBarController && [self.tabBarController respondsToSelector:@selector(triggerNewObservationFlowForTaxon:project:)]) {
            [[Analytics sharedClient] event:kAnalyticsEventNewObservationStart withProperties:@{ @"From": @"TaxonDetails" }];
            [((INatUITabBarController *)self.tabBarController) triggerNewObservationFlowForTaxon:self.taxon
                                                                                         project:nil];
        } else if (self.presentingViewController && [self.presentingViewController respondsToSelector:@selector(triggerNewObservationFlowForTaxon:project:)]) {
            // can't present from the tab bar while it's out of the view hierarchy
            // so dismiss the presented view (ie the parent of this taxon details VC)
            // and then trigger the new observation flow once the tab bar is back
            // in thei heirarchy.
            INatUITabBarController *tabBar = (INatUITabBarController *)self.presentingViewController;
            [tabBar dismissViewControllerAnimated:YES
                                       completion:^{
                                           [[Analytics sharedClient] event:kAnalyticsEventNewObservationStart
                                                            withProperties:@{ @"From": @"TaxonDetails" }];
                                           [tabBar triggerNewObservationFlowForTaxon:self.taxon
                                                                             project:nil];
                                       }];
        }
    }
}

#pragma mark - lifecycle
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"RoundedButtonCell" bundle:[NSBundle mainBundle]]
         forCellReuseIdentifier:@"roundedButton"];
    self.clearsSelectionOnViewWillAppear = YES;
    
    if ([self.taxon isKindOfClass:[Taxon class]]) {
    	self.fullTaxon = (Taxon *)self.taxon;
    	[self.tableView reloadData];
    } else {
	    NSInteger taxonId = self.taxon.taxonId;
	    // try to load taxon from disk in case we have it
	    NSPredicate *taxonPredicate = [NSPredicate predicateWithFormat:@"recordID == %ld", self.taxon.taxonId];
	    self.taxon = [[Taxon objectsWithPredicate:taxonPredicate] firstObject];
        self.fullTaxon = (Taxon *)self.taxon;
        [self.tableView reloadData];

	    if ([[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
	        NSString *urlString = [[NSURL URLWithString:[NSString stringWithFormat:@"/taxa/%ld.json", (long)taxonId]
	                                      relativeToURL:[NSURL inat_baseURL]] absoluteString];
	
	        __weak typeof(self)weakSelf = self;
	        RKObjectLoaderDidLoadObjectBlock loadedTaxonBlock = ^(id object) {
	            
	            // save into core data
	            NSError *saveError = nil;
	            [[[RKObjectManager sharedManager] objectStore] save:&saveError];
	            if (saveError) {
	                NSString *errMsg = [NSString stringWithFormat:@"Taxon Save Error: %@",
	                                    saveError.localizedDescription];
	                [[Analytics sharedClient] debugLog:errMsg];
	                return;
	            }
		            
	            NSPredicate *taxonByIDPredicate = [NSPredicate predicateWithFormat:@"recordID = %d", taxonId];
	            Taxon *taxon = [Taxon objectWithPredicate:taxonByIDPredicate];
	            if (taxon) {
	                __strong typeof(weakSelf)strongSelf = weakSelf;
	                strongSelf.taxon = taxon;
	                strongSelf.fullTaxon = taxon;
	                [strongSelf.tableView reloadData];
	            }
	        };
        
	        [[Analytics sharedClient] debugLog:@"Network - Load taxon for details"];
	        [[RKObjectManager sharedManager] loadObjectsAtResourcePath:urlString
	                                                        usingBlock:^(RKObjectLoader *loader) {
	                                                            loader.objectMapping = [Taxon mapping];
	                                                            loader.onDidLoadObject = loadedTaxonBlock;
	                                                            // If something went wrong, just ignore it.
	                                                            // Because, you know, that's always a good idea.
	                                                        }];
	    }
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.navigationController setToolbarHidden:YES];
    self.navigationController.navigationBar.translucent = NO;
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor inatTint];
    self.navigationItem.leftBarButtonItem.tintColor = [UIColor inatTint];
    [self.navigationItem.leftBarButtonItem setEnabled:YES];
    
    if (!self.delegate) {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

#pragma mark - UITableView
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 1) {
        return [self.fullTaxon.attributedBody boundingRectWithSize:CGSizeMake(290, CGFLOAT_MAX)
                                                       options:NSStringDrawingUsesLineFragmentOrigin
                                                       context:nil].size.height + 20;
    } else if (indexPath.row == 0) {
        TaxonPhoto *tp = self.fullTaxon.taxonPhotos.firstObject;
        NSString *cacheKey = [[SDWebImageManager sharedManager] cacheKeyForURL:[NSURL URLWithString:tp.thumbURL]];
        UIImage *image = [[[SDWebImageManager sharedManager] imageCache] imageFromDiskCacheForKey:cacheKey];
        
        if (image) {
            CGFloat aspectRatio = image.size.height / image.size.width;
            return tableView.bounds.size.width * aspectRatio;
        } else {
            return tableView.bounds.size.width;
        }
    } else {
        return 59;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.0f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.item == 0) {
        TaxonPhotoCell *cell = [tableView dequeueReusableCellWithIdentifier:@"taxonPhoto" forIndexPath:indexPath];
        
        if (self.fullTaxon) {
            TaxonPhoto *tp = self.fullTaxon.taxonPhotos.firstObject;
            if (tp) {
                cell.scrim.hidden = NO;
                [cell.creditsButton setTitle:tp.attribution forState:UIControlStateNormal];
                [cell.creditsButton addTarget:self action:@selector(creditsTapped:) forControlEvents:UIControlEventTouchUpInside];
                
                [cell.taxonPhoto sd_setImageWithURL:[NSURL URLWithString:tp.mediumURL]
                                          completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                  [cell setNeedsDisplay];
                                                  [tableView beginUpdates];
                                                  [tableView endUpdates];
                                              });
                                          }];
            } else {
                cell.scrim.hidden = YES;
                cell.taxonPhoto.image = [[ImageStore sharedImageStore] iconicTaxonImageForName:self.fullTaxon.iconicTaxonName];
            }
        }
        
        return cell;
    } else if (indexPath.item == 1) {
        TaxonSummaryCell *cell = [tableView dequeueReusableCellWithIdentifier:@"taxonSummary" forIndexPath:indexPath];
        
        cell.summaryLabel.attributedText = self.fullTaxon.attributedBody;

        return cell;
    } else {
        RoundedButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:@"roundedButton" forIndexPath:indexPath];
        
        cell.roundedButton.backgroundColor = [UIColor colorWithHex:0xE4E4E4];
        cell.roundedButton.tintColor = [UIColor blackColor];
        [cell.roundedButton setTitle:NSLocalizedString(@"Wikipedia Article", @"title for button to open taxon page on wikipedia")
                            forState:UIControlStateNormal];
        [cell.roundedButton addTarget:self action:@selector(wikipediaTapped:) forControlEvents:UIControlEventTouchUpInside];
        
        return cell;
    }
}

@end
