//
//  TaxonDetailViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/23/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>
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
#import "INatWebController.h"

static const int DefaultNameTag = 1;
static const int TaxonNameTag = 2;
static const int TaxonImageTag = 3;
static const int TaxonImageAttributionTag = 4;
static const int TaxonDescTag = 1;

static char SUMMARY_ASSOCIATED_KEY;

@interface Taxon (Summary)
@property (readonly) NSAttributedString *attributedSummary;
@end

@implementation Taxon (Summary)
// extracting attributed strings from HTML is expensive
// stash the attributed summary in an associated object on the taxon itself
- (NSAttributedString *)attributedSummary {
    NSAttributedString *_attributedSummary = objc_getAssociatedObject(self, &SUMMARY_ASSOCIATED_KEY);
    if (!_attributedSummary) {
        NSData *sumData = [self.wikipediaSummary dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *sumOpts = @{
                                  NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                  NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding),
                                  };
        _attributedSummary = [[NSAttributedString alloc] initWithData:sumData
                                                              options:sumOpts
                                                   documentAttributes:nil
                                                                error:nil];
        objc_setAssociatedObject(self, &SUMMARY_ASSOCIATED_KEY, _attributedSummary, OBJC_ASSOCIATION_COPY);

    }
    return _attributedSummary;
}
@end

@implementation TaxonDetailViewController

@synthesize taxon = _taxon;
@synthesize sectionHeaderViews = _sectionHeaderViews;
@synthesize delegate = _delegate;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)scaleHeaderView:(BOOL)animated
{
    UIImageView *taxonImage = (UIImageView *)[self.tableView.tableHeaderView viewWithTag:TaxonImageTag];
    float width = [UIScreen mainScreen].bounds.size.width;
    float height = fminf(width * taxonImage.image.size.height / taxonImage.image.size.width, width);
    [self.tableView beginUpdates];
    if (animated) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:1.0f];
    }
    [self.tableView.tableHeaderView setFrame:CGRectMake(0, 0, width, height)];
    [self.tableView setTableHeaderView:self.tableView.tableHeaderView];
    [taxonImage setFrame:CGRectMake(0, 0, width, height)];
    if (animated) {
        [UIView commitAnimations];
    }
    [self.tableView endUpdates];
}

- (IBAction)clickedViewMore:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"View more about this species on...",nil)
                                                             delegate:self 
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:NSLocalizedString(@"iNaturalist",nil),
                                  NSLocalizedString(@"EOL",nil), NSLocalizedString(@"Wikipedia",nil), nil];
    if (self.tabBarController) {
        [actionSheet showFromTabBar:self.tabBarController.tabBar];
    } else {
        [actionSheet showInView:self.view];
    }
}

- (IBAction)clickedActionButton:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(taxonDetailViewControllerClickedActionForTaxon:)]) {
        [self.delegate performSelector:@selector(taxonDetailViewControllerClickedActionForTaxon:) 
                            withObject:self.taxon];
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

- (void)initUI
{
    UILabel *defaultNameLabel = (UILabel *)[self.tableView.tableHeaderView viewWithTag:DefaultNameTag];
    UILabel *taxonNameLabel = (UILabel *)[self.tableView.tableHeaderView viewWithTag:TaxonNameTag];
    UILabel *attributionLabel = (UILabel *)[self.tableView.tableHeaderView viewWithTag:TaxonImageAttributionTag];
    UIImageView *taxonImage = (UIImageView *)[self.tableView.tableHeaderView viewWithTag:TaxonImageTag];
    
    defaultNameLabel.text = self.taxon.defaultName;
    if (self.taxon.rankLevel.intValue >= 20) {
        taxonNameLabel.text = [NSString stringWithFormat:@"%@ %@", [self.taxon.rank capitalizedString], self.taxon.name];
        taxonNameLabel.font = [UIFont systemFontOfSize:taxonNameLabel.font.pointSize];
    } else {
        taxonNameLabel.text = self.taxon.name;
    }
    taxonImage.image = nil;
    if (self.taxon.taxonPhotos.count > 0) {
        TaxonPhoto *tp = self.taxon.taxonPhotos.firstObject;
        [taxonImage sd_setImageWithURL:[NSURL URLWithString:tp.mediumURL]
                             completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                 [self scaleHeaderView:YES];
                             }];
        attributionLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Photo %@",nil), tp.attribution];
    } else {
        taxonImage.image = [[ImageStore sharedImageStore] iconicTaxonImageForName:self.taxon.iconicTaxonName];
        attributionLabel.text = @"";
    }
}

#pragma mark - lifecycle
- (void)viewDidLoad
{
    self.clearsSelectionOnViewWillAppear = YES;
    [self initUI];
    if (self.taxon.wikipediaSummary.length == 0 && [[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        NSString *urlString = [[NSURL URLWithString:[NSString stringWithFormat:@"/taxa/%@.json", self.taxon.recordID]
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
            
            NSPredicate *taxonByIDPredicate = [NSPredicate predicateWithFormat:@"recordID = %d", self.taxon.recordID];
            Taxon *taxon = [Taxon objectWithPredicate:taxonByIDPredicate];
            if (taxon) {
                __strong typeof(weakSelf)strongSelf = weakSelf;
                strongSelf.taxon = taxon;
                [strongSelf initUI];
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

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setToolbarHidden:YES];
    self.navigationController.navigationBar.translucent = NO;
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor inatTint];
    self.navigationItem.leftBarButtonItem.tintColor = [UIColor inatTint];
    [self.navigationItem.leftBarButtonItem setEnabled:YES];
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[Analytics sharedClient] timedEvent:kAnalyticsEventNavigateTaxonDetails];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[Analytics sharedClient] endTimedEvent:kAnalyticsEventNavigateTaxonDetails];
}

#pragma mark - UITableView
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row == 0) {
        return [self.taxon.attributedSummary boundingRectWithSize:CGSizeMake(320, 320)
                                                          options:NSStringDrawingUsesLineFragmentOrigin
                                                          context:nil].size.height + 10;
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (!self.sectionHeaderViews) {
        self.sectionHeaderViews = [[NSMutableDictionary alloc] init];
    }
    NSNumber *key = @(section);
    if ([self.sectionHeaderViews objectForKey:key]) {
        return [self.sectionHeaderViews objectForKey:key];
    }
    
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 30)];
    header.backgroundColor = [UIColor whiteColor];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 300, 20)];
    label.font = [UIFont boldSystemFontOfSize:17];
    label.textColor = [UIColor darkGrayColor];
    switch (section) {
        case 0:
            label.text = NSLocalizedString(@"Description",nil);
            break;
        case 1:
            label.text = NSLocalizedString(@"Conservation Status",nil);
            break;
        default:
            break;
    }
    [header addSubview:label];
    
    [self.sectionHeaderViews setObject:header forKey:key];
    return header;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    if (indexPath.section == 0 && indexPath.row == 0) {
        UILabel *label = (UILabel *)[cell viewWithTag:TaxonDescTag];
        label.attributedText = self.taxon.attributedSummary;
        label.numberOfLines = 0;
        label.textColor = [UIColor blackColor];
        label.backgroundColor = [UIColor whiteColor];
        [label sizeToFit];
    } else if (indexPath.section == 1 && indexPath.row == 0) {
        UILabel *title = (UILabel *)[cell viewWithTag:1];
        if (self.taxon.conservationStatusName) {
            title.text = NSLocalizedString(self.taxon.conservationStatusName.humanize, nil);
            if ([self.taxon.conservationStatusName isEqualToString:@"vulnerable"] ||
                [self.taxon.conservationStatusName isEqualToString:@"endangered"] ||
                [self.taxon.conservationStatusName isEqualToString:@"critically_endangered"]) {
                title.textColor = [UIColor colorWithRed:209/255.0 green:47/255.0 blue:25/255.0 alpha:1];
            } else if ([self.taxon.conservationStatusName isEqualToString:@"near_threatened"]) {
                title.textColor = [UIColor orangeColor];
            } else {
                title.textColor = [UIColor blackColor];
            }
        }
    }
    return cell;
}

#pragma mark - ScrollViewDelegate
// This is necessary to stop the section headers from sticking to the top of the screen
// http://stackoverflow.com/questions/664781/change-default-scrolling-behavior-of-uitableview-section-header
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat sectionHeaderHeight = 30;
    if (scrollView.contentOffset.y <= sectionHeaderHeight && scrollView.contentOffset.y >= 0) {
        scrollView.contentInset = UIEdgeInsetsMake(-scrollView.contentOffset.y, 0, 0, 0);
    } else if (scrollView.contentOffset.y>=sectionHeaderHeight) {
        scrollView.contentInset = UIEdgeInsetsMake(-sectionHeaderHeight, 0, 0, 0);
    }
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex > 2) {
        return;
    }
    
    NSString *wikipediaTitle = self.taxon.wikipediaTitle;
    NSString *escapedName = [self.taxon.name stringByAddingURLEncoding];
    NSString *urlString;
    NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
    NSString *countryCode = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
    if (buttonIndex == 0) {
        urlString = [NSString stringWithFormat:@"%@/taxa/%d.mobile?locale=%@-%@", INatWebBaseURL, self.taxon.recordID.intValue, language, countryCode];
    } else if (buttonIndex == 1) {
        urlString = [NSString stringWithFormat:@"http://eol.org/%@", escapedName];
    } else if (buttonIndex == 2) {
        if (!wikipediaTitle) {
            wikipediaTitle = escapedName;
        }
        urlString = [NSString stringWithFormat:@"http://%@.wikipedia.org/wiki/%@", language, wikipediaTitle];
    } else {
        return;
    }
    
    INatWebController *web = [[INatWebController alloc] initWithNibName:nil bundle:nil];
    web.url = [NSURL URLWithString:urlString];
    [self.navigationController pushViewController:web animated:YES];
}

@end
