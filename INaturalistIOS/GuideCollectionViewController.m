//
//  GuideDetailViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 9/4/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import <MBProgressHUD/MBProgressHUD.h>
#import <AFNetworking/UIImageView+AFNetworking.h>
#import <RestKit/RestKit.h>

#import "GuideCollectionViewController.h"
#import "GuideTaxonViewController.h"
#import "GuideViewController.h"
#import "RXMLElement+Helpers.h"
#import "SWRevealViewController.h"
#import "GuidePageViewController.h"
#import "INaturalistAppDelegate.h"
#import "UIColor+INaturalist.h"
#import "Analytics.h"
#import "ImageStore.h"
#import "INatReachability.h"

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
            NSDateComponents *offset = [[NSDateComponents alloc] init];
            [offset setDay:-1];
            if (self.guide.xmlURL && [[INatReachability sharedClient] isNetworkReachable]) {
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
    self.searchBar.backgroundColor = [UIColor redColor];
    self.searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    self.searchBar.delegate = self;
    self.searchBar.tintColor = [UIColor blackColor];
    self.searchBar.placeholder = NSLocalizedString(@"Search", nil);
    self.searchBar.showsCancelButton = NO;
    [self.searchBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    self.searchBar.translucent = NO;
    [self.view addSubview:self.searchBar];
    
    // the collectionview wants to sit under the status bar, but we don't want that
    // since we're adding a search bar
    self.collectionView.contentInset = UIEdgeInsetsMake(40.0, 0.0, 0.0, 0.0);
    
    SWRevealViewController *revealController = [self revealViewController];
    [self.view addGestureRecognizer:revealController.panGestureRecognizer];
    
    if (!self.tags) {
        self.tags = [[NSMutableArray alloc] init];
    }
    
    noContent = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.collectionView.frame) / 2, CGRectGetWidth(self.collectionView.frame), 44)];
    noContent.text = NSLocalizedString(@"No matching taxa", nil);
    noContent.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleBottomMargin;
    noContent.backgroundColor = [UIColor clearColor];
    noContent.textColor = [UIColor lightGrayColor];
    noContent.textAlignment = NSTextAlignmentCenter;
    [noContent setHidden:YES];
    [self.view addSubview:noContent];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBar.translucent = NO;
    [self tintMenuButton];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.navigationController setToolbarHidden:YES animated:animated];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"GuidePageSegue"]) {
        GuidePageViewController *vc = [segue destinationViewController];
        NSInteger gtPosition = [self guideTaxonPositionAtIndexPath:[self.collectionView.indexPathsForSelectedItems objectAtIndex:0]];
        vc.guide = self.guide;
        vc.currentXPath = [self currentXPath];
        vc.currentPosition = gtPosition;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    [self toggleNoContent];
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
    UIImageView *img = (UIImageView *)[cell viewWithTag:100];
    [img cancelImageRequestOperation];
    img.image = [UIImage imageNamed:@"ic_unknown"];
    img.contentMode = UIViewContentModeScaleAspectFill;
    GuideTaxonXML *guideTaxon = [self guideTaxonAtIndexPath:indexPath];
    
    if (guideTaxon) {
        if (guideTaxon.smallPhotoUrl.host) {
            [img setImageWithURL:guideTaxon.smallPhotoUrl
                placeholderImage:[UIImage imageNamed:@"ic_unknown"]];
        } else if (guideTaxon.smallPhotoUrl) {
            [img setImage:[UIImage imageWithContentsOfFile:guideTaxon.smallPhotoUrl.path]];
        }
        
        UILabel *label = (UILabel *)[cell viewWithTag:CellLabelTag];
        label.textAlignment = NSTextAlignmentNatural;
        if (!guideTaxon.displayName || [guideTaxon.displayName isEqualToString:guideTaxon.name]) {
            label.font = [UIFont italicSystemFontOfSize:12.0];
            label.text = guideTaxon.name;
        } else {
            label.font = [UIFont systemFontOfSize:12.0];
            label.text = guideTaxon.displayName;
        }
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"GuidePageSegue" sender:self];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Main use of the scale property
    CGFloat width = [self currentImageWidth];
    return CGSizeMake(width, width);
}


- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.searchBar endEditing:YES];
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
    UITextField *searchField = nil;
    for (UIView *subview in self.searchBar.subviews) {
        if ([subview isKindOfClass:[UITextField class]]) {
            searchField = (UITextField *)subview;
            break;
        }
    }
    UIView *oldRightView;
    if (searchField) {
        // this entire strategy seems excessive, and doesn't seem to work in iOS 7
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        CGRect f = searchField.rightView.frame;
        [spinner setFrame:CGRectMake(10, 0, f.size.height, f.size.height)];
        [spinner setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleRightMargin];
        UIView *wrapper = [[UIView alloc] initWithFrame:f];
        oldRightView = searchField.rightView;
        [wrapper addSubview:spinner];
        [spinner startAnimating];
        searchField.rightView = wrapper;
        searchField.rightViewMode = UITextFieldViewModeAlways;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //        sleep(2); // uncomment to test device-like response time
        [self loadData];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.collectionView reloadData];
            if (searchField) {
                searchField.rightView = oldRightView;
                searchField.rightViewMode = UITextFieldViewModeNever;
            }
            [self toggleNoContent];
        });
    });
    searchTimer = nil;
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    if ([self collectionView:self.collectionView numberOfItemsInSection:0] > 0) {
        // scroll to the first item upon search
        NSIndexPath *first = [NSIndexPath indexPathForItem:0 inSection:0];
        [self.collectionView scrollToItemAtIndexPath:first
                                    atScrollPosition:UICollectionViewScrollPositionTop
                                            animated:YES];

    }
    self.searchBar.showsCancelButton = YES;
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    self.searchBar.frame = CGRectMake(0, 20, CGRectGetWidth(self.collectionView.frame), 44);
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar
{
    self.searchBar.showsCancelButton = NO;
    [self.navigationController setNavigationBarHidden:NO
                                             animated:YES];
    self.searchBar.frame = CGRectMake(0, 0, CGRectGetWidth(self.collectionView.frame), 44);
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.searchBar.text = nil;
    [self searchBar:searchBar textDidChange:@""];
    [self.searchBar endEditing:YES];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
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
    [self loadData];
    [self.collectionView reloadData];
    [self toggleNoContent];
}

- (void)guideMenuControllerRemovedFilterByTag:(NSString *)tag
{
    [self.tags removeObject:tag];
    [self tintMenuButton];
    [self loadData];
    [self.collectionView reloadData];
    [self toggleNoContent];
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
    [self loadData];
    [self.collectionView reloadData];
}

- (void)loadData
{
    if (items) {
        [items removeAllObjects];
    } else {
        items = [[NSMutableArray alloc] init];
    }
    [self.guide iterateWithXPath:self.currentXPath usingBlock:^(RXMLElement *e) {
        [items addObject:[[GuideTaxonXML alloc] initWithGuide:self.guide andXML:e]];
    }];
}

- (void)downloadXML:(NSString *)url
{
    [self downloadXML:url quietly:NO];
}

- (void)downloadXML:(NSString *)url quietly:(BOOL)quietly
{
    if (!quietly) {
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.labelText = NSLocalizedString(@"Loading...",nil);
        hud.removeFromSuperViewOnHide = YES;
        hud.dimBackground = YES;
    }
    NSMutableURLRequest *r = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]
                                                     cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                 timeoutInterval:60];
    if ([(INaturalistAppDelegate *)UIApplication.sharedApplication.delegate loggedIn]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [r setValue:[defaults objectForKey:INatTokenPrefKey] forHTTPHeaderField:@"Authorization"];
    }
    XMLDownloadDelegate *d = [[XMLDownloadDelegate alloc] initWithController:self];
    d.quiet = quietly;
    [[[NSURLConnection alloc] initWithRequest:r
                                     delegate:d] start];
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
    GuideTaxonXML *guideTaxon = nil;
    @try {
        guideTaxon = [items objectAtIndex:indexPath.row];
    } @catch (NSException *exception) {
        // return nil in case of range exceptions
        if (![exception.name isEqualToString:NSRangeException]) {
            @throw exception;
        }
    } @finally {
        return guideTaxon;
    }
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
            [button setTintColor:[UIColor inatTint]];
        } else {
            if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) {
                [button setTintColor:[UIColor blackColor]];
            } else {
                [button setTintColor:[UIColor clearColor]];
            }
        }
    }
}

- (NSString *)currentImageSize
{
    CGFloat w = self.currentImageWidth;
    if (w > 500) {
        return @"large";
    } else if (w > 240) {
        return @"medium";
    } else {
        return @"small";
    }
}

- (CGFloat)currentImageWidth
{
    int numCols = 3;
    CGFloat cellWidth = (self.view.frame.size.width - (numCols+1)*GutterWidth) / numCols;
    return floor(cellWidth*self.scale);
}

- (void)keyboardDidShow:(NSNotification *)notification
{
    NSValue *v = [notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect kbRect = [self.view convertRect:v.CGRectValue toView:nil];
    keyboardHeight = kbRect.size.height;
    [self toggleNoContent];
}

- (void)keyboardDidHide:(NSNotification *)notification
{
    keyboardHeight = 0;
    [self toggleNoContent];
}

- (void)toggleNoContent
{
    CGFloat h = (CGRectGetHeight(self.collectionView.frame) - keyboardHeight) / 2;
    if (keyboardHeight > 0) {
        h = h + 22;
    }
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:0.5f];
    noContent.frame = CGRectMake(0, h, CGRectGetWidth(self.collectionView.frame), 44);
    [noContent setHidden:(items.count != 0)];
    [UIView commitAnimations];
}
@end

@implementation XMLDownloadDelegate
@synthesize progress = _progress;
@synthesize receivedData = _receivedData;
@synthesize expectedBytes = _expectedBytes;
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
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideAllHUDsForView:self.controller.view animated:YES];
    });
    
    if (self.progress) {
        self.progress.hidden = YES;
    }
    
    if (!self.quiet) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Failed to download guide", nil)
                                                                       message:error.localizedDescription
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                  style:UIAlertActionStyleCancel
                                                handler:nil]];
        [self.controller presentViewController:alert animated:YES completion:nil];
    }
}

- (NSCachedURLResponse *) connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}

- (void) connectionDidFinishLoading:(NSURLConnection *)connection {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD hideAllHUDsForView:self.controller.view animated:YES];
    });
    
    if (self.progress) {
        self.progress.hidden = YES;
    }
    
    if (self.lastStatusCode == 200) {
        
        NSError *error;
        if (![self.receivedData writeToFile:self.filePath options:NSDataWritingAtomic error:&error]) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Failed to save guide", nil)
                                                                           message:error.localizedDescription
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            [self.controller presentViewController:alert animated:YES completion:nil];
        }
        [self.controller loadXML:self.filePath];
    } else {
        if (!self.quiet) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Guide download error", nil)
                                                                           message:NSLocalizedString(@"Either there was an error on the server or the guide no longer exists.", nil)
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil)
                                                      style:UIAlertActionStyleCancel
                                                    handler:nil]];
            [self.controller presentViewController:alert animated:YES completion:nil];
        }
    }
}

@end
