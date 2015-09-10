//
//  ConfirmObservationViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 9/4/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>
#import <FontAwesomeKit/FAKIonIcons.h>
#import <FontAwesomeKit/FAKFontAwesome.h>
#import <ActionSheetPicker-3.0/ActionSheetDatePicker.h>
#import <ActionSheetPicker-3.0/ActionSheetStringPicker.h>

#import "ConfirmObservationViewController.h"
#import "Observation.h"
#import "Taxon.h"
#import "TaxonPhoto.h"
#import "ImageStore.h"
#import "UIColor+INaturalist.h"
#import "DisclosureCell.h"
#import "TaxaSearchViewController.h"
#import "ProjectChooserViewController.h"
#import "ProjectObservation.h"
#import "TextViewCell.h"
#import "EditLocationViewController.h"
#import "SubtitleDisclosureCell.h"
#import "PhotoScrollView.h"

typedef NS_ENUM(NSInteger, ConfirmObsSection) {
    ConfirmObsSectionPhotos = 0,
    ConfirmObsSectionIdentify,
    ConfirmObsSectionNotes,
    ConfirmObsSectionCaptive,
    ConfirmObsSectionProjectDetails,
    ConfirmObsSectionProjects
};

@interface ConfirmObservationViewController () <UITableViewDataSource, UITableViewDelegate, UITextViewDelegate, EditLocationViewControllerDelegate>
@property UITableView *tableView;
@property UIButton *saveButton;
@property (readonly) NSString *notesPlaceholder;
@end

@implementation ConfirmObservationViewController

#pragma mark - uiviewcontroller lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView = ({
        UITableView *tv = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        tv.translatesAutoresizingMaskIntoConstraints = NO;

        tv.dataSource = self;
        tv.delegate = self;
        
        // no separator inset
        if ([tv respondsToSelector:@selector(setLayoutMargins:)]) {
            tv.layoutMargins = UIEdgeInsetsZero;
        }
        tv.separatorInset = UIEdgeInsetsZero;
        
        [tv registerClass:[DisclosureCell class] forCellReuseIdentifier:@"disclosure"];
        [tv registerClass:[SubtitleDisclosureCell class] forCellReuseIdentifier:@"subtitleDisclosure"];
        [tv registerClass:[UITableViewCell class] forCellReuseIdentifier:@"photos"];
        [tv registerClass:[UITableViewCell class] forCellReuseIdentifier:@"switch"];
        [tv registerClass:[TextViewCell class] forCellReuseIdentifier:@"notes"];
        
        tv.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tv.bounds.size.width, 0.01f)];
        tv.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tv.bounds.size.width, 0.01f)];

        tv;
    });
    [self.view addSubview:self.tableView];
    
    self.saveButton = ({
        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.frame = CGRectZero;
        button.translatesAutoresizingMaskIntoConstraints = NO;
        
        button.backgroundColor = [UIColor inatTint];
        button.tintColor = [UIColor whiteColor];
        button.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        
        [button setTitle:NSLocalizedString(@"Save", @"Title for save new observation button")
                forState:UIControlStateNormal];
        [button addTarget:self action:@selector(saved:) forControlEvents:UIControlEventTouchUpInside];
        
        button;
    });
    [self.view addSubview:self.saveButton];
    
    NSDictionary *views = @{
                            @"tv": self.tableView,
                            @"save": self.saveButton,
                            };
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[tv]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[save]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];

    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[tv]-[save(==44)]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];

    self.title = NSLocalizedString(@"Details", @"Title for confirm new observation details view");
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
    self.navigationController.navigationBar.tintColor = [UIColor inatTint];
    [self.tableView reloadData];
}

- (void)saved:(UIButton *)button {
    NSError *error;
    [[[RKObjectManager sharedManager] objectStore] save:&error];
    if (error) {
        // log it at least, also notify the user
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITextViewDelegate

- (void)textViewDidBeginEditing:(UITextView *)textView {
    if ([textView.text isEqualToString:self.notesPlaceholder]) {
        textView.textColor = [UIColor blackColor];
        textView.text = @"";
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView {
    self.observation.inatDescription = textView.text;
    
    if (textView.text.length == 0) {
        textView.textColor = [UIColor grayColor];
        textView.text = self.notesPlaceholder;
    }
}

#pragma mark - textview helper
- (NSString *)notesPlaceholder {
    return NSLocalizedString(@"Notes...", @"Placeholder for observation notes when making a new observation.");
}

#pragma mark - geocoding helper
- (void)reverseGeocodeCoordinatesForObservation:(Observation *)obs {
    if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        return;
    }
    
    CLLocation *loc = [[CLLocation alloc] initWithLatitude:obs.latitude.floatValue
                                                 longitude:obs.longitude.floatValue];
    
    static CLGeocoder *geoCoder;
    if (!geoCoder)
        geoCoder = [[CLGeocoder alloc] init];
    
    [geoCoder cancelGeocode];       // cancel anything in flight
    
    [geoCoder reverseGeocodeLocation:loc
                   completionHandler:^(NSArray *placemarks, NSError *error) {
                       CLPlacemark *placemark = [placemarks firstObject];
                       if (placemark) {
                           @try {
                               NSString *name = placemark.name ?: @"";
                               NSString *locality = placemark.locality ?: @"";
                               NSString *administrativeArea = placemark.administrativeArea ?: @"";
                               NSString *ISOcountryCode = placemark.ISOcountryCode ?: @"";
                               obs.placeGuess = [ @[ name,
                                                     locality,
                                                     administrativeArea,
                                                     ISOcountryCode ] componentsJoinedByString:@", "];
                               NSIndexPath *locRowIp = [NSIndexPath indexPathForItem:2 inSection:ConfirmObsSectionNotes];
                               [self.tableView reloadRowsAtIndexPaths:@[ locRowIp ]
                                                     withRowAnimation:UITableViewRowAnimationAutomatic];
                           } @catch (NSException *exception) {
                               if ([exception.name isEqualToString:NSObjectInaccessibleException])
                                   return;
                               else
                                   @throw exception;
                           }
                       }
                   }];
}

#pragma mark - UISwitch targets

- (void)idPleaseChanged:(UISwitch *)switcher {
    self.observation.idPlease = [NSNumber numberWithBool:switcher.isOn];
}

- (void)captiveChanged:(UISwitch *)switcher {
    // set observation captive - not in the local data model yet

}

#pragma mark - Project Chooser

- (void)projectChooserViewController:(ProjectChooserViewController *)controller choseProjects:(NSArray *)projects {
    NSMutableArray *newProjects = [NSMutableArray arrayWithArray:projects];
    NSMutableSet *deletedProjects = [[NSMutableSet alloc] init];
    for (ProjectObservation *po in self.observation.projectObservations) {
        if ([projects containsObject:po.project]) {
            [newProjects removeObject:po.project];
        } else {
            [po deleteEntity];
            [deletedProjects addObject:po];
        }
        self.observation.localUpdatedAt = [NSDate date];
    }
    [self.observation removeProjectObservations:deletedProjects];
    
    for (Project *p in newProjects) {
        ProjectObservation *po = [ProjectObservation object];
        po.observation = self.observation;
        po.project = p;
        self.observation.localUpdatedAt = [NSDate date];
    }
    
    [self.tableView reloadData];
}

#pragma mark - Taxa Search

- (void)taxaSearchViewControllerChoseTaxon:(Taxon *)taxon {
    self.observation.taxon = taxon;
    self.observation.taxonID = taxon.recordID;
    self.observation.iconicTaxonName = taxon.iconicTaxonName;
    self.observation.iconicTaxonID = taxon.iconicTaxonID;
    self.observation.speciesGuess = taxon.defaultName;
    
    [self.navigationController popToViewController:self animated:YES];
}

#pragma mark - EditLocation 

- (void)editLocationViewControllerDidSave:(EditLocationViewController *)controller location:(INatLocation *)location {
    
    if (location.latitude.integerValue == 0 && location.longitude.integerValue == 0) {
        // nothing happens on null island
        return;
    }
    
    self.observation.latitude = location.latitude;
    self.observation.longitude = location.longitude;
    self.observation.positionalAccuracy = location.accuracy;
    self.observation.positioningMethod = location.positioningMethod;
    
    [self.navigationController popToViewController:self animated:YES];

    [self reverseGeocodeCoordinatesForObservation:self.observation];
}

#pragma mark - table view delegate / datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 6;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == ConfirmObsSectionPhotos) {
        return 100;
    } else if (indexPath.section == ConfirmObsSectionNotes && indexPath.item == 0) {
        return 88;
    } else if (indexPath.section == ConfirmObsSectionNotes && indexPath.item == 2) {
        return 66;
    } else {
        return 44;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    switch (section) {
        case ConfirmObsSectionPhotos:
            return 0;
            break;
        case ConfirmObsSectionIdentify:
            return 34;
            break;
        case ConfirmObsSectionNotes:
            return 2;
            break;
        case ConfirmObsSectionCaptive:
            return 2;
            break;
        case ConfirmObsSectionProjectDetails:
            return 34;
            break;
        case ConfirmObsSectionProjects:
            return 34;
            break;
        default:
            return 0;
            break;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case ConfirmObsSectionPhotos:
            return 1;
            break;
        case ConfirmObsSectionIdentify:
            return 2;
            break;
        case ConfirmObsSectionNotes:
            return 4;
            break;
        case ConfirmObsSectionCaptive:
            return 1;
            break;
        case ConfirmObsSectionProjectDetails:
            return 0;
            break;
        case ConfirmObsSectionProjects:
            return 1;
            break;
        default:
            return 0;
            break;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        // no separator inset
        cell.layoutMargins = UIEdgeInsetsZero;
    }
    cell.separatorInset = UIEdgeInsetsZero;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    switch (indexPath.section) {
        case ConfirmObsSectionPhotos:
            return [self photoCellInTableView:tableView];
            break;
        case ConfirmObsSectionIdentify:
            if (indexPath.item == 0) {
                return [self speciesCellInTableView:tableView];
            } else {
                return [self helpIdCellInTableView:tableView];
            }
            break;
        case ConfirmObsSectionNotes:
            if (indexPath.item == 0) {
                return [self notesCellInTableView:tableView];
            } else if (indexPath.item == 1) {
                return [self dateTimeCellInTableView:tableView];
            } else if (indexPath.item == 2) {
                return [self locationCellInTableView:tableView];
            } else if (indexPath.item == 3) {
                return [self geoPrivacyCellInTableView:tableView];
            } else {
                return [self illegalCellForIndexPath:indexPath];
            }
            break;
        case ConfirmObsSectionCaptive:
            return [self captiveCellInTableView:tableView];
            break;
        case ConfirmObsSectionProjectDetails:
            return [self illegalCellForIndexPath:indexPath];
            break;
        case ConfirmObsSectionProjects:
            return [self addProjectCellInTableView:tableView];
            break;
        default:
            return [self illegalCellForIndexPath:indexPath];
            break;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch (indexPath.section) {
        case ConfirmObsSectionPhotos:
            // do nothing
            break;
        case ConfirmObsSectionIdentify:
            if (indexPath.item == 0) {
                TaxaSearchViewController *search = [[TaxaSearchViewController alloc] initWithNibName:nil bundle:nil];
                search.delegate = self;
                search.query = self.observation.speciesGuess;
                [self.navigationController pushViewController:search animated:YES];
            } else {
                // do nothing
            }
            break;
        case ConfirmObsSectionNotes:
            if (indexPath.item == 0) {
                // do nothing
            } else if (indexPath.item == 1) {
                // show date/time action sheet picker
                __weak typeof(self) weakSelf = self;
                [[[ActionSheetDatePicker alloc] initWithTitle:NSLocalizedString(@"Select Date", @"title for date selector")
                                               datePickerMode:UIDatePickerModeDateAndTime
                                                 selectedDate:self.observation.localObservedOn
                                                    doneBlock:^(ActionSheetDatePicker *picker, id selectedDate, id origin) {
                                                        
                                                        __strong typeof(weakSelf) strongSelf = self;
                                                        strongSelf.observation.localObservedOn = selectedDate;
                                                        strongSelf.observation.observedOnString = [Observation.jsDateFormatter stringFromDate:selectedDate];
                                                        
                                                        [strongSelf.tableView reloadRowsAtIndexPaths:@[ indexPath ]
                                                                                    withRowAnimation:UITableViewRowAnimationFade];
                                                        
                                                    } cancelBlock:nil
                                                       origin:self.view] showActionSheetPicker];
            } else if (indexPath.item == 2) {
                // show location chooser
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
                EditLocationViewController *map = [storyboard instantiateViewControllerWithIdentifier:@"EditLocationViewController"];
                map.delegate = self;
                
                if (self.observation.visibleLatitude) {
                    INatLocation *loc = [[INatLocation alloc] initWithLatitude:self.observation.visibleLatitude
                                                                     longitude:self.observation.visibleLongitude
                                                                      accuracy:self.observation.positionalAccuracy];
                    loc.positioningMethod = self.observation.positioningMethod;
                    [map setCurrentLocation:loc];
                } else {
                    [map setCurrentLocation:nil];
                }

                [self.navigationController pushViewController:map animated:YES];
            } else if (indexPath.item == 3) {
                // geoprivacy
                
                // really want swift enums here
                NSArray *geoprivacyOptions = @[@"open", @"obscured", @"private"];
                NSArray *presentableGeoPrivacyOptions = @[
                                                          NSLocalizedString(@"Open", @"open geoprivacy"),
                                                          NSLocalizedString(@"Obscured", @"obscured geoprivacy"),
                                                          NSLocalizedString(@"Private", @"private geoprivacy"),
                                                          ];

                NSInteger selectedIndex = [geoprivacyOptions indexOfObject:self.observation.geoprivacy];
                if (selectedIndex == NSNotFound) {
                    selectedIndex = 0;
                }
                
                __weak typeof(self) weakSelf = self;
                [[[ActionSheetStringPicker alloc] initWithTitle:NSLocalizedString(@"Select Privacy", @"title for geoprivacy selector")
                                                           rows:presentableGeoPrivacyOptions
                                               initialSelection:selectedIndex
                                                      doneBlock:^(ActionSheetStringPicker *picker, NSInteger selectedIndex, id selectedValue) {
                                                          
                                                          __strong typeof(weakSelf) strongSelf = weakSelf;
                                                          
                                                          strongSelf.observation.geoprivacy = geoprivacyOptions[selectedIndex];
                                                          
                                                          [strongSelf.tableView reloadRowsAtIndexPaths:@[ indexPath ]
                                                                                      withRowAnimation:UITableViewRowAnimationFade];

                                                      } cancelBlock:nil
                                                         origin:self.view] showActionSheetPicker];
                
            } else {
                // do nothing
            }
            break;
        case ConfirmObsSectionCaptive:
            // do nothing
            break;
        case ConfirmObsSectionProjectDetails:
            // do nothing
            break;
        case ConfirmObsSectionProjects: {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"unimplemented"
                                                                           message:@"unimplemented"
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                   handler:^(UIAlertAction *action) {
                                                       [alert dismissViewControllerAnimated:YES completion:nil];
                                                   }]];
            [self presentViewController:alert animated:YES completion:nil];
            
            break;
        }
        default:
            // do nothing
            break;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case ConfirmObsSectionPhotos:
            return nil;
            break;
        case ConfirmObsSectionIdentify:
            return NSLocalizedString(@"What did you see?", @"title for identification section of new obs confirm screen.");
            break;
        case ConfirmObsSectionNotes:
            return nil;
            break;
        case ConfirmObsSectionCaptive:
            return nil;
            break;
        case ConfirmObsSectionProjectDetails:
            return NSLocalizedString(@"More", @"title for project obs field section of new obs confirm screen.");
            break;
        case ConfirmObsSectionProjects:
            return NSLocalizedString(@"Projects", @"title for projects  section of new obs confirm screen.");
            break;
        default:
            return nil;
            break;
    }
}

#pragma mark - table view cell helpers

- (UITableViewCell *)photoCellInTableView:(UITableView *)tableView {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"photos"];
    
    PhotoScrollView *photoScrollView = [[PhotoScrollView alloc] initWithFrame:cell.contentView.bounds];
    photoScrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    
    photoScrollView.photos = self.observation.sortedObservationPhotos;
    [cell.contentView addSubview:photoScrollView];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}

- (UITableViewCell *)speciesCellInTableView:(UITableView *)tableView {
    DisclosureCell *cell = [tableView dequeueReusableCellWithIdentifier:@"disclosure"];
    
    Taxon *taxon = self.observation.taxon;
    if (taxon) {
        cell.titleLabel.text = taxon.defaultName;
        if (taxon.isIconic) {
            cell.cellImageView.image = [[ImageStore sharedImageStore] iconicTaxonImageForName:taxon.iconicTaxonName];
        } else if (taxon.taxonPhotos.count > 0) {
            TaxonPhoto *tp = taxon.taxonPhotos.firstObject;
            [cell.cellImageView sd_setImageWithURL:[NSURL URLWithString:tp.thumbURL]];
        } else {
            cell.cellImageView.image = [[ImageStore sharedImageStore] iconicTaxonImageForName:nil];
        }
    } else {
        cell.cellImageView.image = [[ImageStore sharedImageStore] iconicTaxonImageForName:nil];
        cell.titleLabel.text = NSLocalizedString(@"Something...", nil);
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (UITableViewCell *)helpIdCellInTableView:(UITableView *)tableView {
    DisclosureCell *cell = [tableView dequeueReusableCellWithIdentifier:@"disclosure"];
    
    cell.titleLabel.text = @"Help Me ID this Species";
    FAKIcon *bouy = [FAKIonIcons helpBuoyIconWithSize:25];
    [bouy addAttribute:NSForegroundColorAttributeName value:[UIColor grayColor]];
    cell.cellImageView.image = [bouy imageWithSize:CGSizeMake(30, 30)];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    UISwitch *switcher = [[UISwitch alloc] initWithFrame:CGRectZero];
    [switcher addTarget:self action:@selector(idPleaseChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = switcher;
    
    return cell;
}

- (UITableViewCell *)notesCellInTableView:(UITableView *)tableView {
    TextViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"notes"];
    
    if (self.observation.inatDescription && self.observation.inatDescription.length > 0) {
        cell.textView.text = self.observation.inatDescription;
        cell.textView.textColor = [UIColor blackColor];
    } else {
        cell.textView.text = self.notesPlaceholder;
        cell.textView.textColor = [UIColor grayColor];
    }
    cell.textView.delegate = self;

    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;
    return cell;
}

- (UITableViewCell *)dateTimeCellInTableView:(UITableView *)tableView {
    DisclosureCell *cell = [tableView dequeueReusableCellWithIdentifier:@"disclosure"];
    
    cell.titleLabel.text = [self.observation observedOnPrettyString];
    FAKIcon *calendar = [FAKFontAwesome calendarIconWithSize:24];
    [calendar addAttribute:NSForegroundColorAttributeName value:[UIColor grayColor]];
    cell.cellImageView.image = [calendar imageWithSize:CGSizeMake(30, 30)];
    
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (UITableViewCell *)locationCellInTableView:(UITableView *)tableView {
    SubtitleDisclosureCell *cell = [tableView dequeueReusableCellWithIdentifier:@"subtitleDisclosure"];
    
    if (self.observation.latitude && self.observation.longitude) {
        
        NSString *positionalAccuracy = nil;
        if (self.observation.positionalAccuracy) {
            positionalAccuracy = [NSString stringWithFormat:@"%ld m", (long)self.observation.positionalAccuracy.integerValue];
        } else {
            positionalAccuracy = NSLocalizedString(@"???", @"positional accuracy when we don't know");
        }
        NSString *subtitleString = [NSString stringWithFormat:@"Lat: %.3f  Lon: %.3f  Acc: %@",
                                    self.observation.latitude.floatValue,
                                    self.observation.longitude.floatValue,
                                    positionalAccuracy];
        cell.subtitleLabel.text = subtitleString;
        
        if (self.observation.placeGuess && self.observation.placeGuess.length > 0) {
            cell.titleLabel.text = self.observation.placeGuess;
        } else {
            cell.titleLabel.text = NSLocalizedString(@"Location not geocoded", @"place guess when we have lat/lng but it's not geocoded");
            
            // try again
            [self reverseGeocodeCoordinatesForObservation:self.observation];
        }
        
    } else {
        cell.titleLabel.text = NSLocalizedString(@"No location", @"place guess when we have no location information");
    }
        
    FAKIcon *pin = [FAKIonIcons iosLocationOutlineIconWithSize:24];
    [pin addAttribute:NSForegroundColorAttributeName value:[UIColor grayColor]];
    cell.cellImageView.image = [pin imageWithSize:CGSizeMake(30, 30)];
    
    
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (UITableViewCell *)geoPrivacyCellInTableView:(UITableView *)tableView {
    DisclosureCell *cell = [tableView dequeueReusableCellWithIdentifier:@"disclosure"];
    
    cell.titleLabel.text = NSLocalizedString(@"Geo Privacy", @"Geoprivacy button title");
    cell.secondaryLabel.text = self.observation.presentableGeoprivacy;
    
    FAKIcon *globe = [FAKIonIcons iosWorldOutlineIconWithSize:24];
    [globe addAttribute:NSForegroundColorAttributeName value:[UIColor grayColor]];
    cell.cellImageView.image = [globe imageWithSize:CGSizeMake(30, 30)];
    
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (UITableViewCell *)captiveCellInTableView:(UITableView *)tableView {
    DisclosureCell *cell = [tableView dequeueReusableCellWithIdentifier:@"disclosure"];
    
    cell.titleLabel.text = NSLocalizedString(@"Is it captive or cultivated?", @"Captive / cultivated button title.");
    
    FAKIcon *calendar = [FAKIonIcons iosCalendarOutlineIconWithSize:24];
    [calendar addAttribute:NSForegroundColorAttributeName value:[UIColor grayColor]];
    cell.cellImageView.image = [calendar imageWithSize:CGSizeMake(30, 30)];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryNone;
    
    UISwitch *switcher = [[UISwitch alloc] initWithFrame:CGRectZero];
    [switcher addTarget:self action:@selector(captiveChanged:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = switcher;
    
    return cell;
}


- (UITableViewCell *)addProjectCellInTableView:(UITableView *)tableView {
    DisclosureCell *cell = [tableView dequeueReusableCellWithIdentifier:@"disclosure"];
    
    cell.titleLabel.text = NSLocalizedString(@"Add to a Project", @"add to a project button title.");
    FAKIcon *project = [FAKIonIcons iosBriefcaseOutlineIconWithSize:24];
    [project addAttribute:NSForegroundColorAttributeName value:[UIColor grayColor]];
    cell.cellImageView.image = [project imageWithSize:CGSizeMake(30, 30)];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    return cell;
}

- (UITableViewCell *)illegalCellForIndexPath:(NSIndexPath *)ip {
    NSLog(@"indexpath is %@", ip);
    NSAssert(NO, @"shouldn't reach here");
}




@end
