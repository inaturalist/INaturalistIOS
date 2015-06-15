//
//  CategorizeViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 3/24/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <SVProgressHUD/SVProgressHUD.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <HexColors/HexColor.h>
#import <FontAwesomeKit/FAKIonIcons.h>

#import "CategorizeViewController.h"
#import "MultiImageView.h"
#import "Taxon.h"
#import "CategoryChiclet.h"
#import "ObservationDetailViewController.h"
#import "Observation.h"
#import "ObservationPhoto.h"
#import "ImageStore.h"
#import "Observation+AddAssets.h"
#import "Analytics.h"
#import "Project.h"
#import "ProjectObservation.h"

static NSDictionary *ICONIC_TAXON_NAMES;
static NSArray *ICONIC_TAXON_ORDER;

@interface CategorizeViewController () <ObservationDetailViewControllerDelegate> {
    UIView *background;
    
    // can't animate a blurview alpha, so make two containers, one blurred, one not
    // animate the alpha of the blurred one exactly over the unblurred one
    MultiImageView *unblurredMultiImageView;
    MultiImageView *blurredMultiImageView;

    NSArray *iconicTaxa;
    NSFetchRequest *iconicTaxaFetchRequest;
    UIView *categories;
    
    UIButton *skipThisStep;
    UIButton *alwaysSkipThisStep;
    
    NSArray *_assets;
}
@end

@implementation CategorizeViewController

#pragma mark - UIViewController lifecycle

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        
        ICONIC_TAXON_NAMES = @{
                               @"Animalia": @"Animals",
                               @"Actinopterygii": @"Ray-finned Fishes",
                               @"Aves": @"Birds",
                               @"Reptilia": @"Reptiles",
                               @"Amphibia": @"Amphibians",
                               @"Mammalia": @"Mammals",
                               @"Arachnida": @"Arachnids",
                               @"Insecta": @"Insects",
                               @"Plantae": @"Plants",
                               @"Fungi": @"Fungi",
                               @"Protozoa": @"Protozoans",
                               @"Mollusca": @"Mollusks",
                               @"Chromista": @"Chromista"
                               };
        
        ICONIC_TAXON_ORDER = @[
                               @"Mollusca",
                               @"Reptilia",
                               @"Fungi",
                               @"Amphibia",
                               @"Insecta",
                               @"Aves",
                               @"Arachnida",
                               @"Mammalia",
                               @"Plantae",
                               ];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Categorize", @"Title for the categorize page, which also asks the observer to try making an initial ID.");
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    unblurredMultiImageView = ({
        MultiImageView *miv = [[MultiImageView alloc] initWithFrame:CGRectZero];
        miv.translatesAutoresizingMaskIntoConstraints = NO;
        
        miv;
    });
    [self.view addSubview:unblurredMultiImageView];
    
    blurredMultiImageView = ({
        MultiImageView *miv = [[MultiImageView alloc] initWithFrame:CGRectZero];
        miv.translatesAutoresizingMaskIntoConstraints = NO;
        
        miv;
    });
    [self.view addSubview:blurredMultiImageView];
    
    background = ({
        UIView *view;
        if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1) {
            UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
            UIVisualEffectView *blur = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            blur.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
            
            blur.frame = blurredMultiImageView.bounds;

            view = blur;
        } else {
            UIView *scrim = [[UIView alloc] initWithFrame:blurredMultiImageView.bounds];
            scrim.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
            scrim.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7f];
            
            view = scrim;
        }
        
        view;
    });
    
    
    self.navigationItem.backBarButtonItem.tintColor = [UIColor whiteColor];
    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];
    
    [blurredMultiImageView addSubview:background];
    
    categories = ({
        UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
        view.translatesAutoresizingMaskIntoConstraints = NO;
        
        view;
    });
    [self.view addSubview:categories];
    
    skipThisStep = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.frame = CGRectZero;
        button.translatesAutoresizingMaskIntoConstraints = NO;
        
        
        button.tintColor = [UIColor whiteColor];

        button.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:18.0f];
        button.titleLabel.textAlignment = NSTextAlignmentCenter;
        button.contentEdgeInsets = UIEdgeInsetsMake(0, 17.0, 0, 17.0);
        
        [button setTitle:NSLocalizedString(@"Skip for now", @"Button to skip categorizing new observations into iconic taxa")
                forState:UIControlStateNormal];

        // start hidden
        button.alpha = 0.0f;
        
        button.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
        button.layer.borderColor = [UIColor colorWithHexString:@"7a7a7a" alpha:0.5f].CGColor;
        button.layer.borderWidth = 2.0f;
        button.layer.cornerRadius = 2.0f;
        
        __weak typeof(self)weakSelf = self;
        [button bk_addEventHandler:^(id sender) {
            [[Analytics sharedClient] event:kAnalyticsEventNewObservationSkipCategorize
                             withProperties:@{ @"Always": @([[NSUserDefaults standardUserDefaults] boolForKey:kInatCategorizeNewObsPrefKey]) }];
            [weakSelf choseTaxon:nil];
        } forControlEvents:UIControlEventTouchUpInside];
        
        button;
    });
    [self.view addSubview:skipThisStep];
    
    
    alwaysSkipThisStep = ({
        FAKIcon *empty = [FAKIonIcons androidCheckboxOutlineBlankIconWithSize:16.0f];
        [empty addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
        FAKIcon *checked = [FAKIonIcons androidCheckboxOutlineIconWithSize:16.0f];
        [checked addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor]];
        NSString *alwaysSkipText = NSLocalizedString(@"Always skip this step", @"Button to always skip categorizing new observations into iconic taxa");
        
        NSMutableAttributedString *alwaysSkipEmpty = [[NSMutableAttributedString alloc] init];
        [alwaysSkipEmpty appendAttributedString:empty.attributedString];
        [alwaysSkipEmpty appendAttributedString:[[NSAttributedString alloc] initWithString:@"  "]];
        [alwaysSkipEmpty appendAttributedString:[[NSAttributedString alloc] initWithString:alwaysSkipText]];
        
        NSMutableAttributedString *alwaysSkipChecked = [[NSMutableAttributedString alloc] init];
        [alwaysSkipChecked appendAttributedString:checked.attributedString];
        [alwaysSkipChecked appendAttributedString:[[NSAttributedString alloc] initWithString:@"  "]];
        [alwaysSkipChecked appendAttributedString:[[NSAttributedString alloc] initWithString:alwaysSkipText]];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.frame = CGRectZero;
        button.translatesAutoresizingMaskIntoConstraints = NO;
        
        if ([[NSUserDefaults standardUserDefaults] boolForKey:kInatCategorizeNewObsPrefKey]) {
            [button setAttributedTitle:alwaysSkipEmpty forState:UIControlStateNormal];
        } else {
            [button setAttributedTitle:alwaysSkipChecked forState:UIControlStateNormal];
        }

        // start hidden
        button.alpha = 0.0f;

        button.tintColor = [UIColor whiteColor];
        button.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:16.0f];
        button.titleLabel.textAlignment = NSTextAlignmentCenter;

        [button bk_addEventHandler:^(id sender) {
            // toggle
            [[NSUserDefaults standardUserDefaults] setBool:![[NSUserDefaults standardUserDefaults] boolForKey:kInatCategorizeNewObsPrefKey]
                                                    forKey:kInatCategorizeNewObsPrefKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            if ([[NSUserDefaults standardUserDefaults] boolForKey:kInatCategorizeNewObsPrefKey]) {
                [button setAttributedTitle:alwaysSkipEmpty forState:UIControlStateNormal];
            } else {
                [button setAttributedTitle:alwaysSkipChecked forState:UIControlStateNormal];
            }
            
        } forControlEvents:UIControlEventTouchUpInside];
        
        [button sizeToFit];
        [button.titleLabel sizeToFit];
        
        button;
    });
    [self.view addSubview:alwaysSkipThisStep];

    
    NSDictionary *views = @{
                            @"images": blurredMultiImageView,
                            @"bgImages": unblurredMultiImageView,
                            @"categories": categories,
                            @"skip" : skipThisStep,
                            @"alwaysSkip": alwaysSkipThisStep,
                            @"topLayoutGuide": self.topLayoutGuide,
                            };

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[bgImages]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[bgImages]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[images]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[images]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:skipThisStep
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:alwaysSkipThisStep
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0f
                                                           constant:0.0f]];
    
    
    // some combination of FAK and NSAttributedString and UIButton isn't setting intrinsic size correctly
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:alwaysSkipThisStep
                                                          attribute:NSLayoutAttributeWidth
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:nil
                                                          attribute:NSLayoutAttributeNotAnAttribute
                                                         multiplier:1.0f
                                                           constant:[alwaysSkipThisStep.titleLabel.attributedText size].width + 10]];
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[topLayoutGuide]-30-[categories]-30-[skip(==36)]-[alwaysSkip(==36)]"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:categories
                                                          attribute:NSLayoutAttributeCenterX
                                                          relatedBy:NSLayoutRelationEqual
                                                             toItem:self.view
                                                          attribute:NSLayoutAttributeCenterX
                                                         multiplier:1.0f
                                                           constant:0.0f]];
}



- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    [self.navigationController setToolbarHidden:YES animated:NO];
    
    if (self.assets.count > 0) {
        [self configureMultiImageView:blurredMultiImageView forAssets:self.assets];
        [self configureMultiImageView:unblurredMultiImageView forAssets:self.assets];
    }
    
    [self configureCategories];

    blurredMultiImageView.alpha = 0.0f;
    categories.alpha = 0.0f;
}

- (void)viewDidAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [UIView animateWithDuration:0.4f
                     animations:^{
                         blurredMultiImageView.alpha = 1.0f;
                         categories.alpha = 1.0f;
                     } completion:^(BOOL finished) {
                         [UIView animateWithDuration:0.2f
                                          animations:^{
                                              skipThisStep.alpha = 1.0f;
                                              alwaysSkipThisStep.alpha = 1.0f;
                                          }];
                     }];
}

#pragma mark - UI helper

- (void)configureCategories {
    
    // setup the fetch request for the iconic taxa categories
    iconicTaxaFetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Taxon"];
    iconicTaxaFetchRequest.sortDescriptors = @[ [[NSSortDescriptor alloc] initWithKey:@"defaultName" ascending:YES] ];
    [iconicTaxaFetchRequest setPredicate:[NSPredicate predicateWithFormat:@"isIconic == YES"]];
    
    // local fetch of iconic taxa
    NSError *fetchError;
    iconicTaxa = [[NSManagedObjectContext defaultContext] executeFetchRequest:iconicTaxaFetchRequest
                                                                        error:&fetchError];
    if (fetchError) {
        [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"error fetching categories: %@", fetchError.localizedDescription]];
        [SVProgressHUD showErrorWithStatus:fetchError.localizedDescription];
    }
    
    // sort iconic taxa according to
    iconicTaxa = [iconicTaxa sortedArrayUsingComparator:^NSComparisonResult(Taxon *t, Taxon *t2) {
        return [@([ICONIC_TAXON_ORDER indexOfObject:t.name]) compare:@([ICONIC_TAXON_ORDER indexOfObject:t2.name])];
    }];
    
    // remove all the existing buttons
    [categories.subviews bk_each:^(UIView *view) {
        [view removeFromSuperview];
    }];
    
    __weak typeof(self)weakSelf = self;
    // skip fish, other animals, protozoa, chromista
    NSArray *buttons = [[iconicTaxa bk_reject:^BOOL(Taxon *t) {
        if ([t.name isEqualToString:@"Actinopterygii"]) { return YES; }
        if ([t.name isEqualToString:@"Animalia"]) { return YES; }
        if ([t.name isEqualToString:@"Protozoa"]) { return YES; }
        if ([t.name isEqualToString:@"Chromista"]) { return YES; }
        return NO;
    }] bk_map:^id(Taxon *t) {
        CategoryChiclet *chiclet = [CategoryChiclet buttonWithType:UIButtonTypeSystem];
        chiclet.translatesAutoresizingMaskIntoConstraints = NO;
        
        chiclet.categoryLabel.text = ICONIC_TAXON_NAMES[t.name];
        NSString *imageName = [NSString stringWithFormat:@"ic_%@", [t.name lowercaseString]];
        chiclet.categoryImageView.image = [UIImage imageNamed:imageName];
        
        chiclet.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
        chiclet.layer.borderColor = [UIColor colorWithHexString:@"7a7a7a" alpha:0.5f].CGColor;
        chiclet.layer.borderWidth = 2.0f;
        chiclet.layer.cornerRadius = 2.0f;
        
        [chiclet bk_addEventHandler:^(id sender) {
            [[Analytics sharedClient] event:kAnalyticsEventNewObservationCategorizeTaxon
                             withProperties:@{ @"taxon": t.name }];
            [weakSelf choseTaxon:t];
        } forControlEvents:UIControlEventTouchUpInside];
        
        [categories addSubview:chiclet];
        return chiclet;
    }];
    
    if (buttons.count < ICONIC_TAXON_ORDER.count) {
        // didn't get iconic taxa, presumably
        // skip ahead to obs detail view
        __weak typeof(self)weakSelf = self;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf)strongSelf = weakSelf;
            if (strongSelf.navigationController.topViewController == self)
                [strongSelf choseTaxon:nil];
        });
        
        return;
    }
    
    NSDictionary *views = @{
                            @"one":     buttons[0],
                            @"two":     buttons[1],
                            @"three":   buttons[2],
                            @"four":    buttons[3],
                            @"five":    buttons[4],
                            @"six":     buttons[5],
                            @"seven":   buttons[6],
                            @"eight":   buttons[7],
                            @"nine":    buttons[8],
                            };
    
    [categories addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[one(==86)]-5-[two(==86)]-5-[three(==86)]-0-|"
                                                                       options:0
                                                                       metrics:0
                                                                         views:views]];
    [categories addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[four(==86)]-5-[five(==86)]-5-[six(==86)]-0-|"
                                                                       options:0
                                                                       metrics:0
                                                                         views:views]];
    [categories addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[seven(==86)]-5-[eight(==86)]-5-[nine(==86)]-0-|"
                                                                       options:0
                                                                       metrics:0
                                                                         views:views]];
    
    [categories addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[one(==86)]-5-[four(==86)]-5-[seven(==86)]-0-|"
                                                                       options:0
                                                                       metrics:0
                                                                         views:views]];
    [categories addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[two(==86)]-5-[five(==86)]-5-[eight(==86)]-0-|"
                                                                       options:0
                                                                       metrics:0
                                                                         views:views]];
    [categories addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[three(==86)]-5-[six(==86)]-5-[nine(==86)]-0-|"
                                                                       options:0
                                                                       metrics:0
                                                                         views:views]];
}

- (void)configureMultiImageView:(MultiImageView *)miv forAssets:(NSArray *)assets {
    NSArray *images = [assets bk_map:^id(ALAsset *asset) {
        return [UIImage imageWithCGImage:asset.defaultRepresentation.fullScreenImage];
    }];
    miv.images = images;
}

- (void)configureMultiImageView:(MultiImageView *)miv forAssetURL:(NSURL *)assetURL {
    static ALAssetsLibrary *lib;
    
    if (!lib)
        lib = [[ALAssetsLibrary alloc] init];
    
    __weak typeof(self)weakSelf = self;
    [lib assetForURL:assetURL
         resultBlock:^(ALAsset *asset) {
             [weakSelf configureMultiImageView:miv
                                     forAssets:@[ asset ]];
         } failureBlock:^(NSError *error) {
             [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"error reading from AssetsLib: %@", error.localizedDescription]];
         }];

}


#pragma mark - Taxon Choice helper

- (void)choseTaxon:(Taxon *)taxon {
    
    Observation *o = [Observation object];
    
    if (taxon) {
        o.taxon = taxon;
        o.taxonID = taxon.recordID;
        o.iconicTaxonName = taxon.iconicTaxonName;
        o.iconicTaxonID = taxon.iconicTaxonID;
        o.speciesGuess = taxon.defaultName;
    }
    
    if (self.project) {
        ProjectObservation *po = [ProjectObservation object];
        po.observation = o;
        po.project = self.project;
    }
    
    if (self.assets && self.assets.count > 0) {
        [o addAssets:self.assets];
    }
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    ObservationDetailViewController *detail = [storyboard instantiateViewControllerWithIdentifier:@"ObservationDetailViewController"];

    detail.observation = o;
    detail.delegate = self;
    detail.shouldShowBigSaveButton = YES;
    [self.navigationController pushViewController:detail animated:YES];
    if (self.shouldContinueUpdatingLocation)
        [detail startUpdatingLocation];

}

#pragma mark - ObservationDetailViewController delegate

- (void)observationDetailViewControllerDidSave:(ObservationDetailViewController *)controller {
    [[Analytics sharedClient] event:kAnalyticsEventNewObservationSaveObservation];

    NSError *saveError;
    [[Observation managedObjectContext] save:&saveError];
    if (saveError) {
        [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"error saving object store: %@",
                                            saveError.localizedDescription]];
        [SVProgressHUD showErrorWithStatus:saveError.localizedDescription];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)observationDetailViewControllerDidCancel:(ObservationDetailViewController *)controller {
    @try {
        [controller.observation destroy];
    } @catch (NSException *exception) {
        if ([exception.name isEqualToString:NSObjectInaccessibleException]) {
            // if observation has been deleted or is otherwise inaccessible, do nothing
            return;
        }
    }
}


#pragma mark Asset(s) setter/getters

- (void)setAssets:(NSArray *)assets {
    if ([_assets isEqual:assets])
        return;
    
    _assets = assets;
    
    if (blurredMultiImageView)
        [self configureMultiImageView:blurredMultiImageView forAssets:assets];
    
    if (unblurredMultiImageView)
        [self configureMultiImageView:unblurredMultiImageView forAssets:assets];
}

- (NSArray *)assets {
    return _assets;
}

@end
