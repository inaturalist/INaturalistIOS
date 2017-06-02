//
//  TaxonPhotoPageViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 5/23/17.
//  Copyright © 2017 iNaturalist. All rights reserved.
//

#import <MHVideoPhotoGallery/MHGalleryController.h>


#import "TaxonPhotoPageViewController.h"
#import "TaxonPhotoViewController.h"
#import "ImageStore.h"

@interface TaxonPhotoPageViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate>
@property NSMutableArray *pages;
@property UIPageControl *customPageControl;
@property NSInteger pendingIndex;
@property NSInteger currentIndex;
@end

@implementation TaxonPhotoPageViewController

- (void)tapped {
    if (self.taxon.taxonPhotos.count == 0) {
        return;
    }
    
    NSMutableArray *galleryData = [NSMutableArray arrayWithCapacity:self.taxon.taxonPhotos.count];
    NSDictionary *attributionAttrs = @{
                                       NSForegroundColorAttributeName: [UIColor whiteColor],
                                       NSFontAttributeName: [UIFont systemFontOfSize:11.0f],
                                       };
    for (ExploreTaxonPhotoRealm *etpr in self.taxon.taxonPhotos) {
        MHGalleryItem *item = [MHGalleryItem itemWithURL:etpr.largeUrl.absoluteString
                                             galleryType:MHGalleryTypeImage];
        item.attributedString = [[NSAttributedString alloc] initWithString:etpr.attribution
                                                                attributes:attributionAttrs];
        [galleryData addObject:item];
    }
    
    MHUICustomization *customization = [[MHUICustomization alloc] init];
    customization.showOverView = NO;
    customization.hideShare = YES;
    customization.useCustomBackButtonImageOnImageViewer = NO;
    
    MHGalleryController *gallery = [MHGalleryController galleryWithPresentationStyle:MHGalleryViewModeImageViewerNavigationBarShown];
    gallery.galleryItems = galleryData;
    gallery.presentationIndex = self.currentIndex;
    gallery.UICustomization = customization;
    
    __weak MHGalleryController *blockGallery = gallery;
    __weak typeof(self) weakSelf = self;
    gallery.finishedCallback = ^(NSInteger currentIndex, UIImage *image, MHTransitionDismissMHGallery *interactiveTransition, MHGalleryViewMode viewMode) {
        
        __strong typeof(weakSelf)strongSelf = weakSelf;
        __strong typeof(blockGallery)strongGallery = blockGallery;
        dispatch_async(dispatch_get_main_queue(), ^{
            strongSelf.pendingIndex = strongSelf.currentIndex = currentIndex;
            [strongSelf setViewControllers:@[ strongSelf.pages[strongSelf.currentIndex] ]
                                 direction:UIPageViewControllerNavigationDirectionForward
                                  animated:NO
                                completion:nil];
            strongSelf.customPageControl.currentPage = strongSelf.currentIndex;
            [strongGallery dismissViewControllerAnimated:YES completion:nil];
        });
    };
    
    [self presentMHGalleryController:gallery animated:YES completion:nil];

}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.pages = [NSMutableArray arrayWithCapacity:self.taxon.taxonPhotos.count];
    
    // track the current index
    self.pendingIndex = 0;
    self.currentIndex = 0;
    
    self.delegate = self;
    self.dataSource = self;
    
    if (self.taxon.taxonPhotos.count > 0) {
        self.pages = [NSMutableArray arrayWithCapacity:self.taxon.taxonPhotos.count];
        for (int i = 0; i < self.taxon.taxonPhotos.count; i++) {
            TaxonPhotoViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"taxonPhoto"];
            vc.etpr = self.taxon.taxonPhotos[i];
            [self.pages addObject:vc];
        }
        
    } else {
        self.pages = [NSMutableArray arrayWithCapacity:1];
        TaxonPhotoViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"taxonPhoto"];
        vc.imageView.image = [[ImageStore sharedImageStore] iconicTaxonImageForName:self.taxon.iconicTaxonName];
        [self.pages addObject:vc];
    }
    
    [self setViewControllers:@[ [self.pages firstObject] ]
                   direction:UIPageViewControllerNavigationDirectionForward
                    animated:NO
                  completion:nil];
    
    self.customPageControl = ({
        UIPageControl *pageControl = [[UIPageControl alloc] initWithFrame:CGRectZero];
        pageControl.translatesAutoresizingMaskIntoConstraints = NO;
        pageControl.numberOfPages = self.pages.count;
        pageControl.hidden = (self.pages.count < 2);

        pageControl.currentPage = 0;
        
        pageControl;
    });
    [self.view addSubview:self.customPageControl];
    [self.view bringSubviewToFront:self.customPageControl];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[pageControl]-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:@{ @"pageControl": self.customPageControl }]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[pageControl(==20)]-30-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:@{ @"pageControl": self.customPageControl }]];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped)];
    [self.view addGestureRecognizer:tap];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.view bringSubviewToFront:self.customPageControl];
}

- (void)reloadPages {
    if (self.taxon.taxonPhotos.count > 0) {
        self.pages = [NSMutableArray arrayWithCapacity:self.taxon.taxonPhotos.count];
        for (int i = 0; i < self.taxon.taxonPhotos.count; i++) {
            TaxonPhotoViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"taxonPhoto"];
            vc.etpr = self.taxon.taxonPhotos[i];
            [self.pages addObject:vc];
        }
        
    } else {
        self.pages = [NSMutableArray arrayWithCapacity:1];
        TaxonPhotoViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"taxonPhoto"];
        vc.backupImage = [[ImageStore sharedImageStore] iconicTaxonImageForName:self.taxon.iconicTaxonName];
        [self.pages addObject:vc];
    }
    
    [self setViewControllers:@[ [self.pages firstObject] ]
                   direction:UIPageViewControllerNavigationDirectionForward
                    animated:NO
                  completion:nil];

    self.customPageControl.numberOfPages = self.pages.count;
    self.customPageControl.hidden = (self.pages.count < 2);
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController {
    NSInteger currentIndex = [self.pages indexOfObject:viewController];
    NSInteger previousIndex = currentIndex - 1;
    if (previousIndex < 0) {
        return nil;
    } else {
        return self.pages[previousIndex];
    }
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController {
    NSInteger currentIndex = [self.pages indexOfObject:viewController];
    NSInteger nextIndex = currentIndex + 1;
    if (nextIndex >= self.pages.count) {
        return nil;
    } else {
        return self.pages[nextIndex];
    }
}

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray<UIViewController *> *)pendingViewControllers {
    
    self.pendingIndex = [self.pages indexOfObject:[pendingViewControllers firstObject]];
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed {
    
    [self.view bringSubviewToFront:self.customPageControl];
    if (completed) {
        self.currentIndex = self.pendingIndex;
        [self.customPageControl setCurrentPage:self.currentIndex];
    }
}


@end
