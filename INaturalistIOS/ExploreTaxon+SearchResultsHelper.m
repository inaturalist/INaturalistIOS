//
//  Taxon+SearchResultsHelper.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/11/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "ExploreTaxon+SearchResultsHelper.h"
#import "UIFont+ExploreFonts.h"
#import "TaxonPhoto.h"
#import "UIImage+ExploreIconicTaxaImages.h"

@implementation ExploreTaxon (SearchResultsHelper)

- (NSString *)searchResult_Title {
    return self.commonName;
}

- (NSAttributedString *)searchResult_AttributedSubTitle {

    if ([self isGenusOrLower]) {
        // no attributed necessary
        return [[NSAttributedString alloc] initWithString:self.scientificName];
    } else {
        // italiicize the taxon name portion of the subtitle
        NSMutableAttributedString *subtitle = [[NSMutableAttributedString alloc] init];
        NSMutableAttributedString *rank = [[NSMutableAttributedString alloc] initWithString:self.rankName.capitalizedString
                                                                                 attributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:11.0f] }];
        [subtitle appendAttributedString:rank];
        [subtitle appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];;
        NSMutableAttributedString *taxonName = [[NSMutableAttributedString alloc] initWithString:self.scientificName
                                                                                      attributes:@{ NSFontAttributeName: [UIFont fontForTaxonRankName:self.rankName ofSize:11.0f] }];
        [subtitle appendAttributedString:taxonName];
        return subtitle;
    }

    
}

- (NSURL *)searchResult_ThumbnailUrl {
	return self.photoUrl;
}

- (UIImage *)searchResult_PlaceholderImage {
    return [UIImage imageForIconicTaxon:self.iconicTaxonName];
}

@end
