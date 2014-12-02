//
//  PhotoViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/22/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "PhotoViewController.h"
#import "PhotoSource.h"
#import "Analytics.h"

@implementation PhotoViewController

@synthesize deleteButton = _deleteButton;
@synthesize delegate = _delegate;

#pragma mark - UIViewController lifecycle

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[Analytics sharedClient] timedEvent:kAnalyticsEventNavigatePhoto];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[Analytics sharedClient] endTimedEvent:kAnalyticsEventNavigatePhoto];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)viewDidLoad {
    // TTTPhotoViewController defaults to black nav and toolbars
    self.navigationBarStyle = UIBarStyleDefault;
    _toolbar.barStyle = UIBarStyleDefault;
}

#pragma mark - TTPhotoView

- (TTPhotoView *)createPhotoView
{
    if (!self.deleteButton) {
        self.deleteButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash 
                                                                          target:self 
                                                                          action:@selector(deletePhoto:)];
    }
    
    if (_toolbar && [_toolbar.items objectAtIndex:0] != self.deleteButton) {
        UIBarItem* flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:
                           UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem* stub = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:
                                 UIBarButtonSystemItemFixedSpace target:nil action:nil];
        [stub setWidth:[UIScreen mainScreen].bounds.size.width / 12.0];
        _toolbar.items = [[NSArray alloc] initWithObjects:self.deleteButton, flex, _previousButton, flex, _nextButton, flex, stub, nil];
    }
    return [super createPhotoView];
}

- (void)deletePhoto:(id)target
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil 
                                                             delegate:self 
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel",nil)
                                               destructiveButtonTitle:NSLocalizedString(@"Delete photo",nil)
                                                    otherButtonTitles:nil];
    [actionSheet showFromTabBar:self.tabBarController.tabBar];
}

- (void)deleteCenterPhoto
{
    id<TTPhoto> photo = self.centerPhoto;
    PhotoSource *oldPhotoSource = (PhotoSource *)self.photoSource;
    
    if ([self.photoSource respondsToSelector:@selector(removePhoto:)]) {
        [self.photoSource performSelector:@selector(removePhoto:) withObject:photo];
    }
    
    PhotoSource *newPhotoSource = [[PhotoSource alloc] initWithPhotos:oldPhotoSource.photos title:oldPhotoSource.title];
    [self setPhotoSource:newPhotoSource];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(photoViewControllerDeletePhoto:)]) {
        [self.delegate photoViewControllerDeletePhoto:photo];
    }
    
    if (self.photoSource.numberOfPhotos == 0) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self invalidateView]; 
        [self showActivity:nil];
        _thumbsController = nil;
        _centerPhotoIndex = [self.photoSource numberOfPhotos] % (self.centerPhotoIndex + 1);
        _centerPhoto = [self.photoSource photoAtIndex:_centerPhotoIndex];
        [_scrollView reloadData]; 
        [self refresh];
    }
}

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        [self deleteCenterPhoto];
    }
}
@end
