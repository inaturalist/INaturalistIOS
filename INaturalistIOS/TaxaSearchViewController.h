//
//  TaxaSearchViewController.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/30/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

#import "TaxonDetailViewController.h"
#import "TaxonVisualization.h"
#import "ObservationVisualization.h"

@protocol TaxaSearchViewControllerDelegate <NSObject>
- (void)taxaSearchViewControllerChoseTaxon:(id <TaxonVisualization>)taxonId chosenViaVision:(BOOL)visionFlag;
- (void)taxaSearchViewControllerCancelled;
@optional
- (void)taxaSearchViewControllerChoseSpeciesGuess:(NSString *)speciesGuess;
@end

@interface TaxaSearchViewController : UIViewController <TaxonDetailViewControllerDelegate>
@property (nonatomic, weak) id <TaxaSearchViewControllerDelegate> delegate;
@property (nonatomic, strong) NSString *query;
@property (nonatomic, assign) BOOL hidesDoneButton;
@property (nonatomic, assign) BOOL allowsFreeTextSelection;
@property (nonatomic, strong) UIImage *imageToClassify;
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
@property (nonatomic, strong) NSDate *observedOn;
@property (nonatomic, strong) id <ObservationVisualization> observationToClassify;
@end
