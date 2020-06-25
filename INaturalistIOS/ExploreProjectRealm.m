//
//  ExploreProjectRealm.m
//  iNaturalist
//
//  Created by Alex Shepard on 1/6/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

@import UIColor_HTMLColors;

#import "ExploreProjectRealm.h"

@implementation ExploreProjectRealm

+ (NSDictionary *)valueForMantleModel:(ExploreProject *)mtlModel {
    NSMutableDictionary *value = [NSMutableDictionary dictionary];
    value[@"projectId"] = @(mtlModel.projectId);
    
    if (mtlModel.title) { value[@"title"] = mtlModel.title; }
    if (mtlModel.iconUrl) { value[@"iconUrlString"] = mtlModel.iconUrl.absoluteString; }
    if (mtlModel.bannerImageUrl) { value[@"bannerImageUrlString"] = mtlModel.bannerImageUrl.absoluteString; }
    if (mtlModel.bannerColorString) { value[@"bannerColorString"] = mtlModel.bannerColorString; }
    if (mtlModel.inatDescription) { value[@"inatDescription"] = mtlModel.inatDescription; }
    
    if (mtlModel.projectObsFields) {
        NSMutableArray *pofs = [NSMutableArray array];
        for (ExploreProjectObsField *projectObsField in mtlModel.projectObsFields) {
            [pofs addObject:[ExploreProjectObsFieldRealm valueForMantleModel:projectObsField]];
        }
        value[@"projectObsFields"] = [NSArray arrayWithArray:pofs];
    }
    
    value[@"latitude"] = @(mtlModel.latitude);
    value[@"longitude"] = @(mtlModel.longitude);
    value[@"type"] = @(mtlModel.type);
    value[@"locationId"] = @(mtlModel.locationId);
    
    return [NSDictionary dictionaryWithDictionary:value];
}

+ (NSDictionary *)valueForCoreDataModel:(id)cdModel {
    NSMutableDictionary *value = [NSMutableDictionary dictionary];
    
    // already wrapped by core data
    if ([cdModel valueForKey:@"recordID"]) {
        value[@"projectId"] = [cdModel valueForKey:@"recordID"];
    } else {
        // this is not an uploadable, return nil if we don't have a
        // record id
        return nil;
    }
    
    if ([cdModel valueForKey:@"title"]) {
        value[@"title"] = [cdModel valueForKey:@"title"];
    }
    
    if ([cdModel valueForKey:@"iconURL"]) {
        value[@"iconUrl"] = [cdModel valueForKey:@"iconURL"];
    }
    
    if ([cdModel valueForKey:@"desc"]) {
        value[@"inatDescription"] = [cdModel valueForKey:@"desc"];
    }
    
    // supply defaults for nil values
    if ([cdModel valueForKey:@"latitude"]) {
        value[@"latitude"] = [cdModel valueForKey:@"latitude"];
    } else {
        value[@"latitude"] = @(kCLLocationCoordinate2DInvalid.latitude);
    }
    if ([cdModel valueForKey:@"longitude"]) {
        value[@"longitude"] = [cdModel valueForKey:@"longitude"];
    } else {
        value[@"longitude"] = @(kCLLocationCoordinate2DInvalid.longitude);
    }
    
    // no location id for cd projects
    value[@"locationId"] = @(0);
    
    // needs conversion
    if ([cdModel valueForKey:@"projectType"]) {
        if ([[cdModel valueForKey:@"projectType"] isEqualToString:@"collection"]) {
            value[@"type"] = @(ExploreProjectTypeCollection);
        } else if ([[cdModel valueForKey:@"projectType"] isEqualToString:@"umbrella"]) {
            value[@"type"] = @(ExploreProjectTypeUmbrella);
        } else {
            value[@"type"] = @(ExploreProjectTypeOldStyle);
        }
    } else {
        value[@"type"] = @(ExploreProjectTypeOldStyle);
    }
    
    // to-many relationships
    if ([cdModel valueForKey:@"projectObservationFields"]) {
        NSMutableArray *pofs = [NSMutableArray array];
        for (id cdPof in [cdModel valueForKey:@"projectObservationFields"]) {
            [pofs addObject:[ExploreProjectObsFieldRealm valueForCoreDataModel:cdPof]];
        }
        value[@"projectObsFields"] = [NSArray arrayWithArray:pofs];
    }
    
    return [NSDictionary dictionaryWithDictionary:value];    
}

- (instancetype)initWithMantleModel:(ExploreProject *)model {
    if (self = [super init]) {
        self.projectId = model.projectId;
        self.title = model.title;
        self.locationId = model.locationId;
        self.latitude = model.latitude;
        self.longitude = model.longitude;
        self.iconUrlString = model.iconUrl.absoluteString;
        self.bannerImageUrlString = model.bannerImageUrl.absoluteString;
        self.type = model.type;
        self.inatDescription = model.inatDescription;
    }
    return self;
}

+ (NSString *)primaryKey {
    return @"projectId";
}

- (NSURL *)iconUrl {
    return [NSURL URLWithString:self.iconUrlString];
}

- (NSURL *)bannerImageUrl {
    return [NSURL URLWithString:self.bannerImageUrlString];
}

- (UIColor *)bannerColor {
    if (self.bannerColorString) {
        return [UIColor colorWithHexString:self.bannerColorString];
    } else {
        return [UIColor clearColor];
    }
}

+ (NSArray *)titleSortDescriptors {
    return @[
        [RLMSortDescriptor sortDescriptorWithKeyPath:@"title" ascending:YES],
    ];
}

- (NSArray *)sortedProjectObservationFields {
    RLMSortDescriptor *positionSort = [RLMSortDescriptor sortDescriptorWithKeyPath:@"position" ascending:YES];
    RLMResults *sortedResults = [self.projectObsFields sortedResultsUsingDescriptors:@[ positionSort ]];
    // convert to NSArray
    return [sortedResults valueForKey:@"self"];
}

- (BOOL)isNewStyleProject {
    return self.type == ExploreProjectTypeUmbrella || self.type == ExploreProjectTypeCollection;
}

- (NSString *)titleForTypeOfProject {
    if (self.type == ExploreProjectTypeCollection) {
        return NSLocalizedString(@"Collection Project", @"Collection type of project, which automatically collects observations into it.");
    } else if (self.type == ExploreProjectTypeUmbrella) {
        return NSLocalizedString(@"Umbrella Project", @"Umbrella type of project, which contains other projects within it.");
    } else {
        return NSLocalizedString(@"Traditional Project", @"Traditional inat type of project, where users have to manually add observations to the project.");
    }
}

@end
