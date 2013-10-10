//
//  GuideDetailViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 9/4/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import "GuideCollectionViewController.h"
#import "GuideTaxonViewController.h"
#import "GuideViewController.h"
#import "RXMLElement+Helpers.h"
#import <Three20/Three20.h>
#import "SWRevealViewController.h"

static const int CellLabelTag = 200;
static const int GutterWidth  = 5;

@implementation GuideCollectionViewController
@synthesize guide = _guide;
@synthesize guideXMLPath = _guideXMLPath;
@synthesize guideXMLURL = _guideXMLURL;
@synthesize scale = _scale;
@synthesize sort = _sort;
@synthesize searchBar = _searchBar;
@synthesize search = _search;
@synthesize tags = _tags;

#pragma mark - UIViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    [GuideXML setupFilesystem];
    if (!self.guide) {
        if (self.guideXMLPath) {
            self.guide = [[GuideXML alloc] initFromXMLFile:self.guideXMLPath];
        } else if (self.guideXMLURL) {
            [self downloadXML:self.guideXMLURL];
        }
    }
    if (self.guide) {
        self.guideXMLPath = self.guide.xmlPath;
        NSFileManager *fm = [NSFileManager defaultManager];
        if (![fm fileExistsAtPath:self.guide.dirPath]) {
            [fm createDirectoryAtPath:self.guide.dirPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        if ([fm fileExistsAtPath:self.guide.xmlPath]) {
            [self loadXML:self.guideXMLPath];
            self.title = self.guide.title;
            NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
            NSDateComponents *offset = [[NSDateComponents alloc] init];
            [offset setDay:-1];
            if (self.guide.xmlURL
                && RKClient.sharedClient.reachabilityObserver.isNetworkReachable
                ) {
                [self downloadXML:self.guide.xmlURL quietly:YES];
            }
        } else if (self.guide.xmlURL) {
            [self downloadXML:self.guide.xmlURL];
        }
    }

    self.scale = 1.0;
    UIPinchGestureRecognizer *gesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                                                                  action:@selector(didReceivePinchGesture:)];
    [self.collectionView addGestureRecognizer:gesture];
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.collectionView.frame), 44)];
    self.searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    self.searchBar.delegate = self;
    self.searchBar.tintColor = [UIColor blackColor];
    self.searchBar.placeholder = NSLocalizedString(@"Search", nil);
    self.searchBar.showsCancelButton = NO;
    [self.searchBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [self.view addSubview:self.searchBar];
    [self.collectionView setContentOffset:CGPointMake(0, 44)];
    
    SWRevealViewController *revealController = [self revealViewController];
    [self.view addGestureRecognizer:revealController.panGestureRecognizer];
    
    if (!self.tags) {
        self.tags = [[NSMutableArray alloc] init];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self tintMenuButton];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"GuideTaxonSegue"]) {
        GuideTaxonViewController *vc = [segue destinationViewController];
        NSInteger gtPosition = [self guideTaxonPositionAtIndexPath:[self.collectionView.indexPathsForSelectedItems objectAtIndex:0]];
        RXMLElement *rx = [self.guide atXPath:[NSString stringWithFormat:@"(%@)[%d]", [self currentXPath], gtPosition]];
        GuideTaxonXML *gt = [[GuideTaxonXML alloc] initWithGuide:self.guide andXML:rx];
        if (gt) {
            vc.guideTaxon = gt;
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self fitScale];
}

#pragma mark - UICollectionViewDelegate
 -(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (!self.guide) {
        return 0;
    }
    return [self.guide childrenWithRootXPath:[self currentXPath]].count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"GuideTaxonCell";
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:identifier forIndexPath:indexPath];
    TTImageView *img = (TTImageView *)[cell viewWithTag:100];
    [img unsetImage];
    img.urlPath = nil;
    [img setDefaultImage:[UIImage imageNamed:@"iconic_taxon_unknown.png"]];
    img.contentMode = UIViewContentModeCenter;
    GuideTaxonXML *guideTaxon = [self guideTaxonAtIndexPath:indexPath];
    NSString *size = self.scale > 3 ? @"medium" : @"small";
    NSString *localImagePath = [guideTaxon localImagePathForSize:size];
    if (localImagePath) {
        [img setDefaultImage:[UIImage imageWithContentsOfFile:localImagePath]];
        img.urlPath = localImagePath;
        img.contentMode = UIViewContentModeScaleAspectFill;
    } else {
        NSString *remoteImageURL = [guideTaxon remoteImageURLForSize:size];
        if (remoteImageURL) {
            [img setDefaultImage:nil];
            img.urlPath = remoteImageURL;
            img.contentMode = UIViewContentModeScaleAspectFill;
        }
    }
    
    UILabel *label = (UILabel *)[cell viewWithTag:CellLabelTag];
    if (!guideTaxon.displayName || [guideTaxon.displayName isEqualToString:guideTaxon.name]) {
        label.font = [UIFont italicSystemFontOfSize:12.0];
        label.text = guideTaxon.name;
    } else {
        label.font = [UIFont systemFontOfSize:12.0];
        label.text = guideTaxon.displayName;
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"GuideTaxonSegue" sender:self];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Main use of the scale property
    int numCols = 3;
    CGFloat cellWidth = (self.view.frame.size.width - (numCols+1)*GutterWidth) / numCols;
    return CGSizeMake(floor(cellWidth*self.scale), floor(cellWidth*self.scale));
}


#pragma mark - Gesture Recognizers
// http://stackoverflow.com/questions/16406254/zoom-entire-uicollectionview
- (void)didReceivePinchGesture:(UIPinchGestureRecognizer*)gesture
{
    static CGFloat scaleStart;
    
    if (gesture.state == UIGestureRecognizerStateBegan)
    {
        // Take an snapshot of the initial scale
        scaleStart = self.scale;
    }
    else if (gesture.state == UIGestureRecognizerStateChanged)
    {
        // Apply the scale of the gesture to get the new scale
        self.scale = scaleStart * gesture.scale;
        
        // Invalidate layout
        [self.collectionView.collectionViewLayout invalidateLayout];
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        [self fitScale];
    }
}

#pragma mark - UISearchBarDelegate
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    self.search = searchText;
    [searchTimer invalidate];
    searchTimer = nil;
    searchTimer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                                   target:self
                                                 selector:@selector(performSearch)
                                                 userInfo:searchText
                                                  repeats:NO];
}

- (void)performSearch
{
    [self.collectionView reloadData];
    searchTimer = nil;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    self.searchBar.showsCancelButton = YES;
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    self.searchBar.showsCancelButton = NO;
    [self.navigationController setNavigationBarHidden:NO
                                             animated:YES];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.searchBar.text = nil;
    [self searchBar:searchBar textDidChange:nil];
    [self.searchBar endEditing:YES];
}

#pragma mark - GuideMenuControllerDelegate
- (GuideXML *)guideMenuControllerGuide
{
    return self.guide;
}

- (void)guideMenuControllerAddedFilterByTag:(NSString *)tag
{
    [self.tags addObject:tag];
    [self tintMenuButton];
    [self.collectionView reloadData];
}

- (void)guideMenuControllerRemovedFilterByTag:(NSString *)tag
{
    [self.tags removeObject:tag];
    [self tintMenuButton];
    [self.collectionView reloadData];
}

- (void)guideMenuControllerGuideDownloadedNGZForGuide:(GuideXML *)guide
{
    [self.tags removeAllObjects];
    [self loadXML:self.guide.xmlPath];
}

#pragma mark - GuideCollectionViewController
- (void)loadXML:(NSString *)path
{
    self.guide = [self.guide cloneWithXMLFilePath:path];
    self.navigationItem.title = self.guide.title;
    [self.collectionView reloadData];
}

- (void)downloadXML:(NSString *)url
{
    [self downloadXML:url quietly:NO];
}

- (void)downloadXML:(NSString *)url quietly:(BOOL)quietly
{
    if (!quietly) {
        NSString *activityMsg = NSLocalizedString(@"Loading...",nil);
        if (modalActivityView) {
            [[modalActivityView activityLabel] setText:activityMsg];
        } else {
            modalActivityView = [DejalBezelActivityView activityViewForView:self.collectionView
                                                                  withLabel:activityMsg];
        }
    }
    NSURLRequest *theRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:url]
                                                cachePolicy:NSURLRequestUseProtocolCachePolicy
                                            timeoutInterval:60];
    XMLDownloadDelegate *d = [[XMLDownloadDelegate alloc] initWithController:self];
    d.quiet = quietly;
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:theRequest
                                                                  delegate:d
                                                          startImmediately:YES];
}

- (NSString *)currentXPath
{
    NSString *xpath;
    if (self.search && self.search.length != 0) {
        xpath = [NSString stringWithFormat:@"//GuideTaxon/*/text()[contains(translate(., 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'%@')]/ancestor::*[self::GuideTaxon]", [self.search lowercaseString]];
    } else {
        xpath = @"//GuideTaxon";
    }
    if (self.tags.count > 0) {
        NSMutableArray *expressions = [[NSMutableArray alloc] init];
        for (NSString *tag in self.tags) {
            [expressions addObject:[NSString stringWithFormat:@"descendant::tag[text() = '%@']", tag]];
        }
        xpath = [xpath stringByAppendingFormat:@"[%@]", [expressions componentsJoinedByString:@" and "]];
    }
    return xpath;
}

- (NSInteger)guideTaxonPositionAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.sort) {
        // TODO load guideTaxa into an array, sort by the current sort, return physical position of matching GuideTaxon element
        return indexPath.row + 1;
    } else {
        return indexPath.row + 1;
    }
}

- (GuideTaxonXML *)guideTaxonAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger pos = [self guideTaxonPositionAtIndexPath:indexPath];
    RXMLElement *elt = [self.guide atXPath:[NSString stringWithFormat:@"(%@)[%d]", self.currentXPath, pos]];
    return [[GuideTaxonXML alloc] initWithGuide:self.guide andXML:elt];
}

// http://stackoverflow.com/questions/12999510/uicollectionview-animation-custom-layout
- (void)fitScale
{
    CGFloat w = self.view.frame.size.width;
    CGFloat cellWidth = (w - (3+1)*GutterWidth) / 3.0; // default cell width should be 3 cols
    CGFloat scale1 = (w - (1+1)*GutterWidth) / (1 * cellWidth);
    CGFloat scale2 = (w - (2+1)*GutterWidth) / (2 * cellWidth); // 1.525;
    CGFloat scale3 = (w - (3+1)*GutterWidth) / (3 * cellWidth); // 1.0;
    CGFloat scale4 = (w - (4+1)*GutterWidth) / (4 * cellWidth); //0.7375;
    CGFloat scale5 = (w - (5+1)*GutterWidth) / (5 * cellWidth); //0.58;
    CGFloat scale6 = (w - (6+1)*GutterWidth) / (6 * cellWidth); //0.475;
    if (self.scale > scale2) self.scale = scale1;
    else if (self.scale > scale3 && self.scale <= scale2) self.scale = scale2;
    else if (self.scale > scale4 && self.scale <= scale3) self.scale = scale3;
    else if (self.scale > scale5 && self.scale <= scale4) self.scale = scale4;
    else if (self.scale > scale6 && self.scale <= scale5) self.scale = scale5;
    else self.scale = scale6;
    [self.collectionView performBatchUpdates:nil completion:nil];
}

- (void)setScale:(CGFloat)scale
{
    // Make sure it doesn't go out of bounds
    if (scale < 0.475) {
        _scale = 0.475;
    } else if (scale > 3.1) {
        _scale = 3.1;
    } else {
        _scale = scale;
    }
}

- (void)tintMenuButton
{
    UIBarButtonItem *button = self.revealViewController.navigationItem.rightBarButtonItem;
    if (button) {
        if (self.tags.count > 0) {
            [button setTintColor:[UIColor colorWithRed:115.0/255.0 green:172.0/255.0 blue:19.0/255.0 alpha:1]];
        } else {
            [button setTintColor:[UIColor clearColor]];
        }
    }
}

@end

@implementation XMLDownloadDelegate
@synthesize progress = _progress;
@synthesize receivedData = _receivedData;
@synthesize expectedBytes = _expectedBytes;
@synthesize dejalActivityView = _dejalActivityView;
@synthesize lastStatusCode = _lastStatusCode;
@synthesize filePath = _filePath;
@synthesize controller = _controller;
@synthesize quiet = _quiet;

- (id)init
{
    self = [super init];
    if (self) {
        self.receivedData = [[NSMutableData alloc] initWithLength:0];
    }
    return self;
}

- (id)initWithController:(GuideCollectionViewController *)controller
{
    self = [self init];
    if (self) {
        self.controller = controller;
        self.filePath = controller.guideXMLPath;
    }
    return self;
}

- (id)initWithProgress:(UIProgressView *)progress
{
    self = [self init];
    if (self) {
        self.progress = progress;
    }
    return self;
}

- (id)initWithDejalActivityView:(DejalActivityView *)activityView
{
    self = [self init];
    if (self) {
        self.dejalActivityView = activityView;
    }
    return self;
}

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
    self.lastStatusCode = httpResponse.statusCode;
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    if (self.progress) {
        self.progress.hidden = NO;
    }
    [self.receivedData setLength:0];
    self.expectedBytes = [response expectedContentLength];
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.receivedData appendData:data];
    float progressive = (float)[self.receivedData length] / (float)self.expectedBytes;
    if (self.progress) {
        [self.progress setProgress:progressive];
    }
}

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    if (!self.quiet) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failed to download guide",nil)
                                                     message:error.localizedDescription
                                                    delegate:self
                                           cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                           otherButtonTitles:nil];
        [av show];
    }
    [DejalBezelActivityView removeView];
}

- (NSCachedURLResponse *) connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    if (self.progress) {
        self.progress.hidden = YES;
    }
    [DejalBezelActivityView removeView];
    if (self.lastStatusCode == 200) {
        NSError *error;
        if ([self.receivedData writeToFile:self.filePath options:NSDataWritingAtomic error:&error]) {
            NSLog(@"wrote to file: %@", self.filePath);
        } else {
            NSLog(@"failed to write to %@, error: %@", self.filePath, error);
        }
        [self.controller loadXML:self.filePath];
    } else if (!self.quiet) {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failed to download guide",nil)
                                                     message:NSLocalizedString(@"Either there was an error on the server or the guide no longer exists.",nil)
                                                    delegate:self
                                           cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                           otherButtonTitles:nil];
        [av show];
    }
}

@end
