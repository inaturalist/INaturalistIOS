//
//  Taxon+SearchResultsHelper.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/11/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "Taxon+SearchResultsHelper.h"
#import "UIFont+ExploreFonts.h"
#import "TaxonPhoto.h"
#import "UIImage+ExploreIconicTaxaImages.h"

@implementation Taxon (SearchResultsHelper)

- (NSString *)searchResult_Title {
    return self.defaultName;
}

- (NSAttributedString *)searchResult_AttributedSubTitle {

    if (self.isSpeciesOrLower) {
        // no attributed necessary
        return [[NSAttributedString alloc] initWithString:self.name];
    } else {
        // italiicize the taxon name portion of the subtitle
        NSMutableAttributedString *subtitle = [[NSMutableAttributedString alloc] init];
        NSMutableAttributedString *rank = [[NSMutableAttributedString alloc] initWithString:self.rank.capitalizedString
                                                                                 attributes:@{ NSFontAttributeName: [UIFont systemFontOfSize:11.0f] }];
        [subtitle appendAttributedString:rank];
        [subtitle appendAttributedString:[[NSAttributedString alloc] initWithString:@" "]];;
        NSMutableAttributedString *taxonName = [[NSMutableAttributedString alloc] initWithString:self.name
                                                                                      attributes:@{ NSFontAttributeName: [UIFont fontForTaxonRankName:self.rank ofSize:11.0f] }];
        [subtitle appendAttributedString:taxonName];
        return subtitle;
    }

    
}

- (NSURL *)searchResult_ThumbnailUrl {
    return [NSURL URLWithString:((TaxonPhoto *)self.taxonPhotos.firstObject).squareURL];
}

- (UIImage *)searchResult_PlaceholderImage {
    return [UIImage imageForIconicTaxon:self.iconicTaxonName];
}

@end
