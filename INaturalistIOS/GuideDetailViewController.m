//
//  GuideDetailViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 9/4/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import "GuideDetailViewController.h"
#import "GuideTaxonViewController.h"
#import "RXMLElement+Helpers.h"
#import <Three20/Three20.h>
#import "SWRevealViewController.h"

@interface GuideDetailViewController ()

@end

static const int CellLabelTag = 200;

@implementation GuideDetailViewController
@synthesize guide = _guide;
@synthesize ngzData = _ngzData;
@synthesize guideDirPath = _guideDirPath;
@synthesize guideXMLPath = _guideXMLPath;
@synthesize xml = _xml;
@synthesize scale = _scale;
@synthesize sort = _sort;
@synthesize searchBar = _searchBar;
@synthesize search = _search;

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
	// Do any additional setup after loading the view.
    self.title = self.guide.title;
    
    NSFileManager *fm = [NSFileManager defaultManager];
    self.guideDirPath = self.guide.dirPath;
//    NSString *guideNGZPath = [guideDirPath stringByAppendingPathComponent:
//                              [NSString stringWithFormat:@"%@.ngz", self.guide.recordID]];
    if (![fm fileExistsAtPath:self.guideDirPath]) {
        [fm createDirectoryAtPath:self.guideDirPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    self.guideXMLPath = self.guide.xmlPath;
//    if ([fm fileExistsAtPath:self.guideXMLPath]) {
//        [self loadXML:self.guideXMLPath];
//    } else {
        [self downloadXML:self.guide.xmlURL];
//    }

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
}

- (void)viewDidAppear:(BOOL)animated
{
    [self.navigationController setToolbarHidden:YES animated:animated];
}

- (void)loadXML:(NSString *)path
{
    self.xml = [RXMLElement elementFromXMLFilePath:path];
    [self.collectionView reloadData];
}

- (void)downloadXML:(NSString *)url
{
    NSString *activityMsg = NSLocalizedString(@"Loading...",nil);
    if (modalActivityView) {
        [[modalActivityView activityLabel] setText:activityMsg];
    } else {
        modalActivityView = [DejalBezelActivityView activityViewForView:self.collectionView
                                                             withLabel:activityMsg];
    }
    NSURLRequest *theRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:url]
                                                cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
                                            timeoutInterval:60];
    XMLDownloadDelegate *d = [[XMLDownloadDelegate alloc] initWithController:self];
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:theRequest
                                                                   delegate:d
                                                           startImmediately:YES];
}

- (void)downloadNGZ:(NSString *)path
{
//    NSString *ngzURL = [NSString stringWithFormat:@"%@/guides/%d.ngz", INatBaseURL, self.guide.recordID.integerValue];
//    NSURL *url = [NSURL URLWithString:ngzURL];
//    NSURLRequest *theRequest = [NSURLRequest requestWithURL:url
//                                                cachePolicy:NSURLRequestReloadIgnoringLocalCacheData
//                                            timeoutInterval:60];
//    self.ngzData = [[NSMutableData alloc] initWithLength:0];
//    NSURLConnection * connection = [[NSURLConnection alloc] initWithRequest:theRequest
//                                                                   delegate:self
//                                                           startImmediately:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSString *)currentXPath
{
    NSString *xpath;
    if (self.search && self.search.length != 0) {
        xpath = [NSString stringWithFormat:@"//GuideTaxon/*/text()[contains(translate(., 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'),'%@')]/ancestor::*[self::GuideTaxon]", [self.search lowercaseString]];
    } else {
        xpath = @"//GuideTaxon";
    }
    return xpath;
}

#pragma mark UICollectionViewDelegate
 -(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (!self.xml) {
        return 0;
    }
    return [self.xml childrenWithRootXPath:[self currentXPath]].count;
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
    NSInteger gtPosition = [self guideTaxonPositionAtIndexPath:indexPath];
    RXMLElement *localHref = [self.xml atXPath:
                           [NSString stringWithFormat:@"%@[%d]/GuidePhoto[1]/href[@type='local' and @size='small']", [self currentXPath], gtPosition]];
    BOOL imgSet = false;
    if (localHref) {
        NSString *imgPath = [self.guideDirPath stringByAppendingPathComponent:[localHref text]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:imgPath]) {
            [img setDefaultImage:[UIImage imageWithContentsOfFile:imgPath]];
            imgSet = true;
            img.contentMode = UIViewContentModeScaleAspectFill;
        }
    }

    if (!imgSet) {
        NSString *xpath = [NSString stringWithFormat:@"(%@)[%d]/GuidePhoto[1]/href[@type='remote' and @size='small']", [self currentXPath], gtPosition];
        RXMLElement *remoteHref = [self.xml atXPath:xpath];
        if (remoteHref) {
            [img setDefaultImage:nil];
            img.urlPath = [remoteHref text];
            img.contentMode = UIViewContentModeScaleAspectFill;
            imgSet = true;
        }
    }
    
    UILabel *label = (UILabel *)[cell viewWithTag:CellLabelTag];
    RXMLElement *displayNameElt = [self.xml atXPath:[NSString stringWithFormat:@"(%@)[%d]/displayName", [self currentXPath], gtPosition]];
    RXMLElement *nameElt = [self.xml atXPath:[NSString stringWithFormat:@"(%@)[%d]/name", [self currentXPath], gtPosition]];
    NSString *displayName = displayNameElt.text;
    NSString *name = nameElt.text;
    if ([displayName isEqualToString:name]) {
        label.font = [UIFont italicSystemFontOfSize:12.0];
        label.text = name;
    } else {
        label.font = [UIFont systemFontOfSize:12.0];
        label.text = displayName;
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"GuideTaxonSegue" sender:self];
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"GuideTaxonSegue"]) {
        GuideTaxonViewController *vc = [segue destinationViewController];
        NSInteger gtPosition = [self guideTaxonPositionAtIndexPath:[self.collectionView.indexPathsForSelectedItems objectAtIndex:0]];
        RXMLElement *gt = [self.xml atXPath:
                           [NSString stringWithFormat:@"%@[%d]", [self currentXPath], gtPosition]];
        if (gt) {
            vc.xmlString = gt.xmlString;
        }
    }
}

#pragma mark - UICollectionViewDelegateFlowLayout
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Main use of the scale property
    return CGSizeMake(100*self.scale, 100*self.scale);
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

// http://stackoverflow.com/questions/12999510/uicollectionview-animation-custom-layout
- (void)fitScale
{
    CGFloat w = self.view.frame.size.width;
    CGFloat gutter = 5.0;
    CGFloat scale1 = (w - (1+1)*gutter) / 100.0;
    CGFloat scale2 = (w - (2+1)*gutter) / 200.0; // 1.525;
    CGFloat scale3 = (w - (3+1)*gutter) / 300.0; // 1.0;
    CGFloat scale4 = (w - (4+1)*gutter) / 400.0; //0.7375;
    CGFloat scale5 = (w - (5+1)*gutter) / 500.0; //0.58;
    CGFloat scale6 = (w - (6+1)*gutter) / 600.0; //0.475;
    if (self.scale > scale2) self.scale = scale1;
    else if (self.scale > scale3 && self.scale <= scale2) self.scale = scale2;
    else if (self.scale > scale4 && self.scale <= scale3) self.scale = scale3;
    else if (self.scale > scale5 && self.scale <= scale4) self.scale = scale4;
    else if (self.scale > scale6 && self.scale <= scale5) self.scale = scale5;
    else self.scale = scale6;
    [self.collectionView performBatchUpdates:nil completion:nil];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self fitScale];
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

#pragma UISearchBarDelegate
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    self.search = searchText;
    
    // this is exessively slow, but works. A better approach might involve nstimer to wait a bit before reloading the data
    [self.collectionView reloadData];
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

#pragma GuideMenuControllerDelegate
- (RXMLElement *)guideMenuControllerXML
{
    return self.xml;
}

- (void)guideMenuControllerDidFilterByTag:(NSString *)tag
{
    NSLog(@"guideMenuControllerDidFilterByTag: %@", tag);
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

- (id)init
{
    self = [super init];
    if (self) {
        self.receivedData = [[NSMutableData alloc] initWithLength:0];
    }
    return self;
}

- (id)initWithController:(GuideDetailViewController *)controller
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
}

- (NSCachedURLResponse *) connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    NSError *error;
    if ([self.receivedData writeToFile:self.filePath options:NSDataWritingAtomic error:&error]) {
        NSLog(@"wrote to file: %@", self.filePath);
    } else {
        NSLog(@"failed to write to %@, error: %@", self.filePath, error);
    }
    if (self.progress) {
        self.progress.hidden = YES;
    }
    [DejalBezelActivityView removeView];
    if (self.lastStatusCode == 200) {
        [self.controller loadXML:self.filePath];
    } else {
        UIAlertView *av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Failed to download guide",nil)
                                                     message:NSLocalizedString(@"Either there was an error on the server or the guide no longer exists.",nil)
                                                    delegate:self
                                           cancelButtonTitle:NSLocalizedString(@"OK",nil)
                                           otherButtonTitles:nil];
        [av show];
    }
}

@end
