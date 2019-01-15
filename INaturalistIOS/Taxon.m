//
//  Taxon.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/21/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "Taxon.h"
#import "TaxonPhoto.h"
#import "NSString+Helpers.h"
#import <TapkuLibrary/NSString+TKCategory.h>

static RKManagedObjectMapping *defaultMapping = nil;

@implementation Taxon

@dynamic recordID;
@dynamic createdAt;
@dynamic updatedAt;
@dynamic localCreatedAt;
@dynamic localUpdatedAt;
@dynamic syncedAt;
@dynamic name;
@dynamic parentID;
@dynamic iconicTaxonID;
@dynamic iconicTaxonName;
@dynamic isIconic;
@dynamic observationsCount;
@dynamic listedTaxaCount;
@dynamic rankLevel;
@dynamic uniqueName;
@dynamic wikipediaSummary;
@dynamic wikipediaTitle;
@dynamic ancestry;
@dynamic conservationStatusName;
@dynamic defaultName;
@dynamic conservationStatusCode;
@dynamic conservationStatusSourceName;
@dynamic rank;
@dynamic taxonPhotos;
@dynamic listedTaxa;

+ (RKManagedObjectMapping *)mapping
{
    if (!defaultMapping) {
        defaultMapping = [RKManagedObjectMapping mappingForClass:[self class] inManagedObjectStore:[RKManagedObjectStore defaultObjectStore]];
        [defaultMapping mapKeyPathsToAttributes:
         @"id", @"recordID",
         @"created_at", @"createdAt",
         @"updated_at", @"updatedAt",
         @"name", @"name",
         @"ancestry", @"ancestry",
         @"conservation_status", @"conservationStatusCode",
         @"conservation_status_name", @"conservationStatusName",
         @"conservation_status_source.title", @"conservationStatusSourceName",
         @"common_name.name", @"defaultName",
         @"iconic_taxon_name", @"iconicTaxonName",
         @"iconic_taxon_id", @"iconicTaxonID",
         @"is_iconic", @"isIconic",
         @"listed_taxa_count", @"listedTaxaCount",
         @"observations_count", @"observationsCount",
         @"parent_id", @"parentID",
         @"rank", @"rank",
         @"rank_level", @"rankLevel",
         @"unique_name", @"uniqueName",
         @"wikipedia_summary", @"wikipediaSummary",
         @"wikipedia_title", @"wikipediaTitle",
         nil];
        [defaultMapping mapKeyPath:@"taxon_photos" 
                    toRelationship:@"taxonPhotos" 
                       withMapping:[TaxonPhoto mapping]
                         serialize:NO];
        defaultMapping.primaryKeyAttribute = @"recordID";
    }
    return defaultMapping;
}

+ (UIColor *)iconicTaxonColor:(NSString *)iconicTaxonName
{
    if (!iconicTaxonName) {
        iconicTaxonName = @"";
    }
    if ([iconicTaxonName isEqualToString:@"Protozoa"]) {
        return [UIColor colorWithRed:105/255.0 green:23/255.0 blue:118/255.0 alpha:1];
    }
    else if ([iconicTaxonName isEqualToString:@"Plantae"]) {
        return [UIColor colorWithRed:115/255.0 green:172/255.0 blue:19/255.0 alpha:1];
    }
    else if ([iconicTaxonName isEqualToString:@"Fungi"]) {
        return [UIColor colorWithRed:255/255.0 green:20/255.0 blue:147/255.0 alpha:1];
    }
    else if ([iconicTaxonName isEqualToString:@"Animalia"]) {
        return [UIColor colorWithRed:30/255.0 green:144/255.0 blue:255/255.0 alpha:1];
    }
    else if ([iconicTaxonName isEqualToString:@"Amphibia"]) {
        return [UIColor colorWithRed:30/255.0 green:144/255.0 blue:255/255.0 alpha:1];
    }
    else if ([iconicTaxonName isEqualToString:@"Reptilia"]) {
        return [UIColor colorWithRed:30/255.0 green:144/255.0 blue:255/255.0 alpha:1];
    }
    else if ([iconicTaxonName isEqualToString:@"Aves"]) {
        return [UIColor colorWithRed:30/255.0 green:144/255.0 blue:255/255.0 alpha:1];
    }
    else if ([iconicTaxonName isEqualToString:@"Mammalia"]) {
        return [UIColor colorWithRed:30/255.0 green:144/255.0 blue:255/255.0 alpha:1];
    }
    else if ([iconicTaxonName isEqualToString:@"Actinopterygii"]) {
        return [UIColor colorWithRed:30/255.0 green:144/255.0 blue:255/255.0 alpha:1];
    }
    else if ([iconicTaxonName isEqualToString:@"Mollusca"]) {
        return [UIColor colorWithRed:255/255.0 green:69/255.0 blue:0/255.0 alpha:1];
    }
    else if ([iconicTaxonName isEqualToString:@"Arachnida"]) {
        return [UIColor colorWithRed:255/255.0 green:69/255.0 blue:0/255.0 alpha:1];
    }
    else if ([iconicTaxonName isEqualToString:@"Insecta"]) {
        return [UIColor colorWithRed:255/255.0 green:69/255.0 blue:0/255.0 alpha:1];
    }
    else if ([iconicTaxonName isEqualToString:@"Chromista"]) {
        return [UIColor colorWithRed:153/255.0 green:51/255.0 blue:0/255.0 alpha:1];
    }
    else {
        return [UIColor blackColor];
    }
}

- (NSArray *)children
{
    NSString *queryAncestry;
    if (self.ancestry && self.ancestry.length > 0) {
        queryAncestry = [NSString stringWithFormat:@"%@/%d", self.ancestry, self.recordID.intValue];
    } else {
        queryAncestry = [NSString stringWithFormat:@"%d", self.recordID.intValue];
    }
    NSFetchRequest *request = [Taxon fetchRequest];
    request.predicate = [NSPredicate predicateWithFormat:@"ancestry = %@", queryAncestry];
    request.sortDescriptors = [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES]];
    return [Taxon objectsWithFetchRequest:request];
}

- (BOOL)isSpeciesOrLower
{
    return (self.rankLevel.intValue > 0 && self.rankLevel.intValue <= 10);
}

- (BOOL)isGenusOrLower
{
    return (self.rankLevel.intValue > 0 && self.rankLevel.intValue <= 20);
}

- (NSArray *)sortedTaxonPhotos
{
    NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"position" ascending:YES];
    NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"createdAt" ascending:YES];
    return [self.taxonPhotos
            sortedArrayUsingDescriptors:
            [NSArray arrayWithObjects:sortDescriptor1, sortDescriptor2, nil]];
}

- (BOOL)fullyLoaded
{
    return self.defaultName.length > 0 && self.rank.length > 0;
}

- (NSURL *)wikipediaUrl {
    NSString *langLocale = [[NSLocale preferredLanguages] firstObject];
    NSString *lang = [[langLocale componentsSeparatedByString:@"-"] firstObject];
    NSString *urlEncodedTaxon = [self.name URLEncode];
    NSString *articleTitle;
    
    // the server sometimes sends "" and sometimes null for empty wikipedia_title
    // in either case, fallback to using scientific name
    if (self.wikipediaTitle && [self.wikipediaTitle length] > 0) {
        articleTitle = self.wikipediaTitle;
    } else {
        articleTitle = urlEncodedTaxon;
    }
    NSString *urlString = [NSString stringWithFormat:@"https://%@.wikipedia.org/wiki/%@", lang, articleTitle];
    return [NSURL URLWithString:urlString];
}

#pragma mark - TaxonVisualization

- (NSString *)rankName {
    return self.rank;
}

- (NSInteger)taxonId {
    return [self.recordID integerValue];
}

- (NSString *)scientificName {
    return self.name;
}

- (NSString *)commonName {
    return self.defaultName;
}

- (NSURL *)photoUrl {
    TaxonPhoto *tp = self.sortedTaxonPhotos.firstObject;
    if (tp && tp.smallURL) {
        return [NSURL URLWithString:tp.smallURL];
    } else {
        return nil;
    }
}

@end
