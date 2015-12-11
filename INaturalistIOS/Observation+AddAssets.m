//
//  Observation+AddAssets.m
//  iNaturalist
//
//  Created by Alex Shepard on 3/27/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreLocation/CoreLocation.h>

#import "Observation+AddAssets.h"
#import "ObservationPhoto.h"
#import "ImageStore.h"

@implementation Observation (AddAssets)

- (void)addAssets:(NSArray *)assets afterEach:(void (^)(ObservationPhoto *))afterEachBlock {
    NSDate *now = [NSDate date];
    
    __block BOOL hasDate = self.observedOn != nil;
    __block BOOL hasLocation = self.latitude != nil;
    
    NSInteger initialObsPhotoCount = self.observationPhotos.count;
    
    [assets enumerateObjectsUsingBlock:^(ALAsset *asset, NSUInteger idx, BOOL *stop) {
        ObservationPhoto *op = [ObservationPhoto object];
        op.position = @(initialObsPhotoCount + idx);
        [op setObservation:self];
        [op setPhotoKey:[ImageStore.sharedImageStore createKey]];
        
        NSError *saveError = nil;
        
        BOOL saved = [[ImageStore sharedImageStore] storeAsset:asset
                                                        forKey:op.photoKey
                                                         error:&saveError];
        if (saveError) {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Photo Save Error", @"Title for photo save error alert msg")
                                        message:saveError.localizedDescription
                                       delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                              otherButtonTitles:nil] show];
            [op destroy];
            return;
        } else if (!saved) {
            [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Photo Save Error", @"Title for photo save error alert msg")
                                        message:NSLocalizedString(@"Unknown error", @"Message body when we don't know the error")
                                       delegate:nil
                              cancelButtonTitle:NSLocalizedString(@"OK", nil)
                              otherButtonTitles:nil] show];
            [op destroy];
            return;
        }

        op.localCreatedAt = now;
        op.localUpdatedAt = now;
        
        if (!hasDate) {
            if ([asset valueForProperty:ALAssetPropertyDate]) {
                hasDate = YES;
                self.observedOn = [asset valueForProperty:ALAssetPropertyDate];
                self.localObservedOn = self.observedOn;
                self.observedOnString = [Observation.jsDateFormatter stringFromDate:self.localObservedOn];
            }
        }
        
        if (!hasLocation) {
            NSDictionary *metadata = asset.defaultRepresentation.metadata;
            if ([metadata valueForKeyPath:@"{GPS}.Latitude"] && [metadata valueForKeyPath:@"{GPS}.Longitude"]) {
                hasLocation = YES;
                
                double latitude, longitude;
                if ([[metadata valueForKeyPath:@"{GPS}.LatitudeRef"] isEqualToString:@"N"]) {
                    latitude = [[metadata valueForKeyPath:@"{GPS}.Latitude"] doubleValue];
                } else {
                    latitude = -1 * [[metadata valueForKeyPath:@"{GPS}.Latitude"] doubleValue];
                }
                
                if ([[metadata valueForKeyPath:@"{GPS}.LongitudeRef"] isEqualToString:@"E"]) {
                    longitude = [[metadata valueForKeyPath:@"{GPS}.Longitude"] doubleValue];
                } else {
                    longitude = -1 * [[metadata valueForKeyPath:@"{GPS}.Longitude"] doubleValue];
                }
                
                self.latitude = @(latitude);
                self.longitude = @(longitude);
                
                [self reverseGeocodeLocation:[[CLLocation alloc] initWithLatitude:latitude
                                                                        longitude:longitude]];
            }
            
        }
        
        if (afterEachBlock) {
            afterEachBlock(op);
        }
        
    }];
    
    NSError *saveError;
    [[Observation managedObjectContext] save:&saveError];
    if (saveError) {
        NSLog(@"SAVE ERROR: %@", saveError);
    }
}

- (void)addAssets:(NSArray *)assets {
    [self addAssets:assets afterEach:nil];
}

- (void)reverseGeocodeLocation:(CLLocation *)loc {
    if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        return;
    }
    
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
                               self.placeGuess = [ @[ name,
                                                      locality,
                                                      administrativeArea,
                                                      ISOcountryCode ] componentsJoinedByString:@", "];
                           } @catch (NSException *exception) {
                               if ([exception.name isEqualToString:NSObjectInaccessibleException])
                                   return;
                               else
                                   @throw exception;
                           }
                       }
                   }];
    
}


@end
