//
//  ObsDetailViewModel.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/17/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>
#import <UIColor-HTMLColors/UIColor+HTMLColors.h>
#import <FontAwesomeKit/FAKIonIcons.h>

#import "ObsDetailViewModel.h"
#import "Observation.h"
#import "User.h"
#import "Taxon.h"
#import "TaxonPhoto.h"
#import "ImageStore.h"
#import "ObservationPhoto.h"
#import "PhotosPageControlCell.h"
#import "DisclosureCell.h"
#import "SubtitleDisclosureCell.h"
#import "NSURL+INaturalist.h"
#import "Analytics.h"
#import "FAKINaturalist.h"
#import "ObsDetailInfoViewModel.h"
#import "ObsDetailActivityViewModel.h"
#import "ObsDetailFavesViewModel.h"
#import "UIColor+INaturalist.h"
#import "ObsDetailSelectorHeaderView.h"
#import "ObsDetailTaxonCell.h"
#import "INaturalistAppDelegate.h"
#import "LoginController.h"
#import "UIColor+ExploreColors.h"
#import "INatPhoto.h"
#import "UIImage+INaturalist.h"

@interface ObsDetailViewModel ()

@property NSInteger viewingPhoto;

@end

@implementation ObsDetailViewModel

- (instancetype)init {
    if (self = [super init]) {
    }
    
    return self;
}

- (void)dealloc {
    [[[RKClient sharedClient] requestQueue] cancelRequestsWithDelegate:(id <RKRequestDelegate>)self];
}

#pragma mark - UITableView datasource/delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // hack
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 3;
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // first four rows of section 0 are shared among all view models
    if (indexPath.section == 0) {
        if (indexPath.item == 0) {
            return [self userDateCellForTableView:tableView];
        } else if (indexPath.item == 1) {
            return [self photoCellForTableView:tableView];
        } else if (indexPath.item == 2) {
            return [self taxonCellForTableView:tableView indexPath:indexPath];
        }
    } else {
        return nil;
    }
}

- (UITableViewCell *)userDateCellForTableView:(UITableView *)tableView {
    DisclosureCell *cell = [tableView dequeueReusableCellWithIdentifier:@"disclosure"];
    
    cell.cellImageView.layer.cornerRadius = 27.0 / 2;
    cell.cellImageView.clipsToBounds = YES;


    if (self.observation.inatRecordId) {
        if ([self.observation userThumbUrl]) {
            [cell.cellImageView sd_setImageWithURL:[NSURL URLWithString:self.observation.userThumbUrl]];
        } else {
            cell.cellImageView.image = [UIImage inat_defaultUserImage];
        }
        cell.titleLabel.text = self.observation.username;
    } else {
        // me
        INaturalistAppDelegate *appDelegate = (INaturalistAppDelegate *)[[UIApplication sharedApplication] delegate];
        if (appDelegate.loginController.isLoggedIn) {
            User *user = [appDelegate.loginController fetchMe];
            if (user.userIconURL) {
                [cell.cellImageView sd_setImageWithURL:[NSURL URLWithString:user.userIconURL]];
            } else {
                cell.cellImageView.image = [UIImage inat_defaultUserImage];
            }
            cell.titleLabel.text = user.login;
        } else {
            cell.titleLabel.text = @"Me";            
            cell.cellImageView.image = [UIImage inat_defaultUserImage];
        }
    }

    cell.secondaryLabel.text = self.observation.observedOnShortString;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (UITableViewCell *)photoCellForTableView:(UITableView *)tableView {
    // photos
    PhotosPageControlCell *cell = [tableView dequeueReusableCellWithIdentifier:@"photos"];
    
    if (self.observation.observationPhotos.count > 0) {
        id <INatPhoto> op = self.observation.sortedObservationPhotos[self.viewingPhoto];
        if (op.photoKey) {
            cell.iv.image = [[ImageStore sharedImageStore] find:op.photoKey forSize:ImageStoreLargeSize];
        } else {
            [cell.iv sd_setImageWithURL:op.largePhotoUrl];
        }
    } else {
        // show iconic taxon image
        FAKIcon *taxonIcon = [FAKINaturalist iconForIconicTaxon:self.observation.iconicTaxonName
                                                       withSize:200];

        [taxonIcon addAttribute:NSForegroundColorAttributeName
                           value:[UIColor lightGrayColor]];
        
        cell.iv.image = [taxonIcon imageWithSize:CGSizeMake(200, 200)];
        cell.iv.contentMode = UIViewContentModeCenter;  // don't scale
    }
    
    if (self.observation.observationPhotos.count > 1) {
        cell.pageControl.hidden = NO;
        cell.pageControl.numberOfPages = self.observation.observationPhotos.count;
        cell.pageControl.currentPage = self.viewingPhoto;
        [cell.pageControl addTarget:self
                             action:@selector(pageControlChanged:)
                   forControlEvents:UIControlEventValueChanged];
        
        
        UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                                         action:@selector(swiped:)];
        swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
        [cell addGestureRecognizer:swipeRight];
        
        UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                                        action:@selector(swiped:)];
        swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
        [cell addGestureRecognizer:swipeLeft];
    } else {
        cell.pageControl.hidden = YES;
    }
    
    [cell.shareButton addTarget:self
                         action:@selector(share)
               forControlEvents:UIControlEventTouchUpInside];
    
    if (self.observation.inatRecordId) {
        cell.shareButton.hidden = NO;
    } else {
        cell.shareButton.hidden = YES;
    }
    
    cell.captiveContainer.hidden = !self.observation.captive.boolValue;
    [cell.captiveInfoButton addTarget:self
                               action:@selector(captiveInfoPressed)
                     forControlEvents:UIControlEventTouchUpInside];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (UITableViewCell *)taxonCellForTableView:(UITableView *)tableView indexPath:(NSIndexPath *)indexPath {
    ObsDetailTaxonCell *cell = [tableView dequeueReusableCellWithIdentifier:@"taxonFromNib"];

    NSPredicate *taxonPredicate = [NSPredicate predicateWithFormat:@"recordID == %ld", self.observation.taxonID.integerValue];
    Taxon *taxon = [[Taxon objectsWithPredicate:taxonPredicate] firstObject];

    cell.taxonNameLabel.textColor = [UIColor blackColor];

    if (taxon) {
        
        if ([taxon.name isEqualToString:taxon.defaultName] || taxon.defaultName == nil) {
            // no common name, so only show scientific name in the main label
            cell.taxonNameLabel.text = taxon.name;
            cell.taxonSecondaryNameLabel.text = nil;
            
            if (taxon.isGenusOrLower) {
                cell.taxonNameLabel.font = [UIFont italicSystemFontOfSize:17];
                cell.taxonNameLabel.text = taxon.name;
            } else {
                cell.taxonNameLabel.font = [UIFont systemFontOfSize:17];
                cell.taxonNameLabel.text = [NSString stringWithFormat:@"%@ %@",
                                            [taxon.rank capitalizedString], taxon.name];
            }
        } else {
            // show both common & scientfic names
            cell.taxonNameLabel.text = taxon.defaultName;
            cell.taxonNameLabel.font = [UIFont systemFontOfSize:17];
            
            if (!taxon.fullyLoaded || taxon.isGenusOrLower) {
                cell.taxonSecondaryNameLabel.font = [UIFont italicSystemFontOfSize:14];
                cell.taxonSecondaryNameLabel.text = taxon.name;
            } else {
                cell.taxonSecondaryNameLabel.font = [UIFont systemFontOfSize:14];
                cell.taxonSecondaryNameLabel.text = [NSString stringWithFormat:@"%@ %@",
                                                     [taxon.rank capitalizedString], taxon.name];

            }
        }

        
        if ([taxon.isIconic boolValue]) {
            cell.taxonImageView.image = [[ImageStore sharedImageStore] iconicTaxonImageForName:taxon.iconicTaxonName];
        } else if (taxon.taxonPhotos.count > 0) {
            TaxonPhoto *tp = taxon.taxonPhotos.firstObject;
            [cell.taxonImageView sd_setImageWithURL:[NSURL URLWithString:tp.thumbURL]];
        } else {
            cell.taxonImageView.image = [[ImageStore sharedImageStore] iconicTaxonImageForName:taxon.iconicTaxonName];
        }
        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        FAKIcon *question = [FAKINaturalist speciesUnknownIconWithSize:44];
        [question addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithHexString:@"#777777"]];
        cell.taxonImageView.image = [question imageWithSize:CGSizeMake(44, 44)];
        // the question icon has a rendered border
        cell.taxonImageView.layer.borderWidth = 0.0f;

        if (self.observation.speciesGuess) {
            cell.taxonNameLabel.text = self.observation.speciesGuess;
        } else {
            cell.taxonNameLabel.text = NSLocalizedString(@"Unknown", @"unknown taxon");
        }
    }
    
    if (!taxon || !taxon.fullyLoaded) {
        // fetch complete taxon
        if ([[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
            
            NSString *resource = [NSString stringWithFormat:@"/taxa/%ld.json", (long)self.observation.taxonID.integerValue];
            
            __weak typeof(self) weakSelf = self;
            RKObjectLoaderDidLoadObjectBlock taxonLoadedBlock = ^(id object) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                
                Taxon *loadedTaxon = (Taxon *)object;
                loadedTaxon.syncedAt = [NSDate date];
                
                // save into core data
                NSError *saveError = nil;
                [[[RKObjectManager sharedManager] objectStore] save:&saveError];
                if (saveError) {
                    NSString *errMsg = [NSString stringWithFormat:@"Taxon Save Error: %@",
                                        saveError.localizedDescription];
                    [[Analytics sharedClient] debugLog:errMsg];
                    return;
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [strongSelf.delegate reloadTableView];
                });
                
            };
            
            [[Analytics sharedClient] debugLog:@"Network - Load a partially loaded taxon"];
            [[[RKObjectManager sharedManager] mappingProvider] setMapping:[Taxon mapping] forKeyPath:@""];
            [[RKObjectManager sharedManager] loadObjectsAtResourcePath:resource
                                                            usingBlock:^(RKObjectLoader *loader) {
                                                                loader.onDidLoadObject = taxonLoadedBlock;
                                                            }];
            
        } else {
            NSLog(@"no network, ignore");
        }
    }
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return nil;
    } else if (section == 1) {
        ObsDetailSelectorHeaderView *selector = [tableView dequeueReusableHeaderFooterViewWithIdentifier:@"selectorHeader"];
        
        [selector.infoButton addTarget:self
                                action:@selector(selectedInfo:)
                      forControlEvents:UIControlEventTouchUpInside];
        
        [selector.activityButton addTarget:self
                                    action:@selector(selectedActivity:)
                          forControlEvents:UIControlEventTouchUpInside];
        
        // only show the activity count if there's unviewed activity on this obs
        if (self.observation.hasUnviewedActivity.boolValue) {
            selector.activityButton.count = self.observation.sortedActivity.count;
        } else {
            selector.activityButton.count = 0;
        }
        
        [selector.favesButton addTarget:self
                                 action:@selector(selectedFaves:)
                       forControlEvents:UIControlEventTouchUpInside];
        // don't show faves count for now
        selector.favesButton.count = 0;
        
        if (self.sectionType == ObsDetailSectionInfo) {
            selector.infoButton.enabled = NO;
        } else if (self.sectionType == ObsDetailSectionActivity) {
            selector.activityButton.enabled = NO;
        } else if (self.sectionType == ObsDetailSectionFaves) {
            selector.favesButton.enabled = NO;
        }

        return selector;
    }
    return nil;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.item == 0) {
            // user
            return 44;
        } else if (indexPath.item == 1) {
            // wider tableview shows more photo,
            if (tableView.bounds.size.width > 369) {
                return 253;
            } else {
                return 200;
            }
        } else if (indexPath.item == 2) {
            // taxon
            return 60;
        }
    }
    
    return CGFLOAT_MIN;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return CGFLOAT_MIN;
    } else if (section == 1) {
        return 69.0f;
    }
    return CGFLOAT_MIN;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 0) {
        if (indexPath.item == 0) {
            // do nothing
        } else if (indexPath.item == 1) {
            // photos segue
            if (self.observation.observationPhotos.count > 0) {
                [self.delegate inat_performSegueWithIdentifier:@"photos" sender:@(self.viewingPhoto)];
            }
        } else if (indexPath.item == 2) {
            // taxa segue
            if (self.observation.taxonID && [[self.observation taxonID] integerValue] != 0) {
                [self.delegate inat_performSegueWithIdentifier:@"taxon" sender:[self.observation taxonID]];
            } else {
                // do nothing
            }
        }
    }
}

#pragma mark - UITableView helpers


#pragma mark - uicontrol events

- (void)share {
    [self.delegate inat_performSegueWithIdentifier:@"share" sender:nil];
}


- (void)pageControlChanged:(UIPageControl *)pageControl {
    self.viewingPhoto = pageControl.currentPage;
    
    NSIndexPath *photoIp = [NSIndexPath indexPathForItem:1 inSection:0];
    [self.delegate reloadRowAtIndexPath:photoIp];
}

- (void)captiveInfoPressed {
    NSString *captiveTitle = NSLocalizedString(@"What does captive / cultivated mean?", @"title for alert explaining what captive means");
    NSString *captiveMsg = NSLocalizedString(@"Captive / cultivated means that the organism exists where it was observed because humans intended it to be there. iNaturalist is about observing wild organisms, and our scientific data partners are not interested in observations of pets, gardens, or animals in zoos.", @"message explaining what captive / cultivated means for iNaturalist");
    
    [[[UIAlertView alloc] initWithTitle:captiveTitle
                                message:captiveMsg
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"OK", nil)
                      otherButtonTitles:nil] show];
}

#pragma mark - gestures

- (void)swiped:(UISwipeGestureRecognizer *)gesture {
    NSIndexPath *photoIp = [NSIndexPath indexPathForItem:1 inSection:0];
    
    if (gesture.direction == UISwipeGestureRecognizerDirectionRight) {
        // swiping backward
        if (self.viewingPhoto == 0) {
            // do nothing
        } else {
            self.viewingPhoto--;
            [self.delegate reloadRowAtIndexPath:photoIp withAnimation:UITableViewRowAnimationRight];
        }

    } else if (gesture.direction == UISwipeGestureRecognizerDirectionLeft) {
        // swiping forward
        if (self.viewingPhoto + 1 == self.observation.observationPhotos.count) {
            // do nothing
        } else {
            self.viewingPhoto++;
            [self.delegate reloadRowAtIndexPath:photoIp withAnimation:UITableViewRowAnimationLeft];
        }
    }
}

- (ObsDetailSection)sectionType {
    return ObsDetailSectionNone;
}


- (void)selectedInfo:(UIButton *)button {
    [[Analytics sharedClient] event:kAnalyticsEventObservationChangeSection
                     withProperties:@{ @"New Section": @"Info" }];
    [self.delegate selectedSection:ObsDetailSectionInfo];
}

- (void)selectedActivity:(UIButton *)button {
    [[Analytics sharedClient] event:kAnalyticsEventObservationChangeSection
                     withProperties:@{ @"New Section": @"Activity" }];
    [self.delegate selectedSection:ObsDetailSectionActivity];
}

- (void)selectedFaves:(UIButton *)button {
    [[Analytics sharedClient] event:kAnalyticsEventObservationChangeSection
                     withProperties:@{ @"New Section": @"Faves" }];
    [self.delegate selectedSection:ObsDetailSectionFaves];
}


@end
