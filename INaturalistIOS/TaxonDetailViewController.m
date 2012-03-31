//
//  TaxonDetailViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/23/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "TaxonDetailViewController.h"
#import "Taxon.h"
#import "Observation.h"
#import "TaxonPhoto.h"
#import "ImageStore.h"
#import "ObservationDetailViewController.h"

static const int DefaultNameTag = 1;
static const int TaxonNameTag = 2;
static const int TaxonImageTag = 3;
static const int TaxonImageAttributionTag = 4;
static const int TaxonDescTag = 1;

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
    TTImageView *taxonImage = (TTImageView *)[self.tableView.tableHeaderView viewWithTag:TaxonImageTag];
    float height = fminf(320 * taxonImage.image.size.height / taxonImage.image.size.width, 320);
    [self.tableView beginUpdates];
    if (animated) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:1.0f];
    }
    [self.tableView.tableHeaderView setFrame:CGRectMake(0, 0, 320, height)];
    [self.tableView setTableHeaderView:self.tableView.tableHeaderView];
    [taxonImage setFrame:CGRectMake(0, 0, 320, height)];
    if (animated) {
        [UIView commitAnimations];
    }
    [self.tableView endUpdates];
}

- (IBAction)clickedViewWikipedia:(id)sender {
    NSString *wikipediaTitle = self.taxon.wikipediaTitle;
    if (!wikipediaTitle) {
        wikipediaTitle = [self.taxon.name stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    }
    NSURL *url = [NSURL URLWithString:
                  [NSString stringWithFormat:@"http://en.wikipedia.org/wiki/%@", wikipediaTitle]];
    [[UIApplication sharedApplication] openURL:url];
}

- (IBAction)clickedActionButton:(id)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(taxonDetailViewControllerClickedActionForTaxon:)]) {
        [self.delegate performSelector:@selector(taxonDetailViewControllerClickedActionForTaxon:) 
                            withObject:self.taxon];
    } else {
        [self performSegueWithIdentifier:@"AddObservationSegue" sender:nil];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"AddObservationSegue"]) {
        ObservationDetailViewController *vc = [segue destinationViewController];
        Observation *o = [Observation object];
        o.localObservedOn = [NSDate date];
        o.taxon = self.taxon;
        o.speciesGuess = self.taxon.defaultName;
        [vc setObservation:o];
    }
}

#pragma mark - lifecycle
- (void)viewDidLoad
{
    self.clearsSelectionOnViewWillAppear = YES;
    UILabel *defaultNameLabel = (UILabel *)[self.tableView.tableHeaderView viewWithTag:DefaultNameTag];
    UILabel *taxonNameLabel = (UILabel *)[self.tableView.tableHeaderView viewWithTag:TaxonNameTag];
    UILabel *attributionLabel = (UILabel *)[self.tableView.tableHeaderView viewWithTag:TaxonImageAttributionTag];
    TTImageView *taxonImage = (TTImageView *)[self.tableView.tableHeaderView viewWithTag:TaxonImageTag];
    
    defaultNameLabel.text = self.taxon.defaultName;
    if (self.taxon.rankLevel.intValue >= 20) {
        taxonNameLabel.text = [NSString stringWithFormat:@"%@ %@", [self.taxon.rank capitalizedString], self.taxon.name];
        taxonNameLabel.font = [UIFont systemFontOfSize:taxonNameLabel.font.pointSize];
    } else {
        taxonNameLabel.text = self.taxon.name;
    }
    taxonImage.defaultImage = [[ImageStore sharedImageStore] iconicTaxonImageForName:self.taxon.iconicTaxonName];
    if (self.taxon.taxonPhotos.count > 0) {
        TaxonPhoto *tp = self.taxon.taxonPhotos.firstObject;
        taxonImage.urlPath = tp.mediumURL;
        taxonImage.delegate = self;
        attributionLabel.text = [NSString stringWithFormat:@"Photo %@", tp.attribution];
        if ([taxonImage isLoaded]) {
            [self scaleHeaderView:NO];
        }
    } else {
        attributionLabel.text = @"";
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [self.navigationController setToolbarHidden:YES];
    [super viewWillAppear:animated];
}

#pragma mark - UITableView
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row == 0) {
        CGSize s = [self.taxon.wikipediaSummary sizeWithFont:[UIFont systemFontOfSize:15] 
                                           constrainedToSize:CGSizeMake(320, 320) 
                                               lineBreakMode:UILineBreakModeWordWrap];
        return s.height + 10;
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
    NSNumber *key = [NSNumber numberWithInt:section];
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
            label.text = @"Description";
            break;
        case 1:
            label.text = @"Conservation Status";
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
        TTStyledTextLabel *descLabel = (TTStyledTextLabel *)[cell viewWithTag:TaxonDescTag];
        if (!descLabel.text) {
            descLabel.text = [TTStyledText textFromXHTML:self.taxon.wikipediaSummary
                                              lineBreaks:NO 
                                                    URLs:YES];
            [descLabel sizeToFit];
            descLabel.backgroundColor = [UIColor whiteColor];
        }
    } else if (indexPath.section == 1 && indexPath.row == 0) {
        UILabel *title = (UILabel *)[cell viewWithTag:1];
//        UILabel *subtitle = (UILabel *)[cell viewWithTag:2];
        if (self.taxon.conservationStatusName) {
            title.text = self.taxon.conservationStatusName.humanize;
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

#pragma mark - TTImageViewDelegate
- (void)imageView:(TTImageView *)imageView didLoadImage:(UIImage *)image
{
    [self scaleHeaderView:YES];
}

@end
