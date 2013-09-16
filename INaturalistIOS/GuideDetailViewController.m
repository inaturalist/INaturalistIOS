//
//  GuideDetailViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 9/4/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import "GuideDetailViewController.h"
#import <Three20/Three20.h>

@interface GuideDetailViewController ()

@end

@implementation GuideDetailViewController
@synthesize guide = _guide;
@synthesize ngzData = _ngzData;
@synthesize guideDirPath = _guideDirPath;
@synthesize guideXMLPath = _guideXMLPath;
@synthesize xml = _xml;
@synthesize scale = _scale;
@synthesize sort = _sort;

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
    [self.navigationController setToolbarHidden:YES];
    self.title = self.guide.title;
    
    NSFileManager *fm = [NSFileManager defaultManager];
    NSArray *docDirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [docDirs objectAtIndex:0];
    NSString *guidesDirPath = [docDir stringByAppendingPathComponent:@"guides"];
    self.guideDirPath = [guidesDirPath stringByAppendingPathComponent:self.guide.recordID.stringValue];
    if (![fm fileExistsAtPath:self.guideDirPath]) {
        [fm createDirectoryAtPath:self.guideDirPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
//    NSString *guideNGZPath = [guideDirPath stringByAppendingPathComponent:
//                              [NSString stringWithFormat:@"%@.ngz", self.guide.recordID]];
    self.guideXMLPath = [self.guideDirPath stringByAppendingPathComponent:
                              [NSString stringWithFormat:@"%@.xml", self.guide.recordID]];
    if ([fm fileExistsAtPath:self.guideXMLPath]) {
        [self loadXML:self.guideXMLPath];
    } else {
        NSString *guideXMLURL = [NSString stringWithFormat:@"%@/guides/%@.xml", INatBaseURL, self.guide.recordID];
        [self downloadXML:guideXMLURL];
    }
    
    self.scale = 1.0;
    UIPinchGestureRecognizer *gesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                                                                  action:@selector(didReceivePinchGesture:)];
    [self.collectionView addGestureRecognizer:gesture];
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

#pragma mark UICollectionViewDelegate
 -(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    if (!self.xml) {
        return 0;
    }
    return [self.xml childrenWithRootXPath:@"//GuideTaxon"].count;
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
    NSArray *localHrefs = [self.xml childrenWithRootXPath:
                           [NSString stringWithFormat:@"//GuideTaxon[%d]/GuidePhoto[1]/href[@type='local' and @size='medium']", gtPosition]];
    BOOL imgSet = false;
    if (localHrefs.count > 0) {
        RXMLElement *localHref = [localHrefs objectAtIndex:0];
        NSString *imgPath = [self.guideDirPath stringByAppendingPathComponent:[localHref text]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:imgPath]) {
            [img setDefaultImage:[UIImage imageWithContentsOfFile:imgPath]];
            imgSet = true;
            img.contentMode = UIViewContentModeScaleAspectFill;
        }
    }

    if (!imgSet) {
        NSString *xpath = [NSString stringWithFormat:@"//GuideTaxon[%d]/GuidePhoto[1]/href[@type='remote' and @size='medium']", gtPosition];
        NSArray *remoteHrefs = [self.xml childrenWithRootXPath:xpath];
        if (remoteHrefs.count > 0) {
            RXMLElement *remoteHref = [remoteHrefs objectAtIndex:0];
            img.urlPath = [remoteHref text];
            img.contentMode = UIViewContentModeScaleAspectFill;
            imgSet = true;
        }
    }
    return cell;
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
