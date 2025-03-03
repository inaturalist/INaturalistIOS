//
//  TaxonVisualization.h
//  iNaturalist
//
//  Created by Alex Shepard on 6/27/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TaxonVisualization <NSObject>

- (NSInteger)taxonId;
- (NSString *)commonName;
- (NSString *)scientificName;
- (NSURL *)photoUrl;
- (NSURL *)representativePhotoUrl;
- (NSString *)rankName;
- (NSInteger)rankLevel;
- (NSString *)iconicTaxonName;

- (NSString *)displayFirstName;
- (BOOL)displayFirstNameIsItalicized;
- (NSString *)displaySecondName;
- (BOOL)displaySecondNameIsItalicized;

- (BOOL)isGenusOrLower;

- (NSURL *)wikipediaUrl;
- (NSString *)wikipediaArticleName;
- (BOOL)isActive;

@end
