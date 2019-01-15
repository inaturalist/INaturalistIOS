//
//  Project.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/12/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "Project.h"
#import "ProjectObservation.h"
#import "ProjectObservationField.h"
#import "ProjectUser.h"

static RKManagedObjectMapping *defaultMapping = nil;
//static RKManagedObjectMapping *defaultSerializationMapping = nil;

@implementation Project

@dynamic title;
@dynamic desc;
@dynamic terms;
@dynamic createdAt;
@dynamic updatedAt;
@dynamic iconURL;
@dynamic projectType;
@dynamic cachedSlug;
@dynamic observedTaxaCount;
@dynamic localCreatedAt;
@dynamic localUpdatedAt;
@dynamic syncedAt;
@dynamic recordID;
@dynamic projectObservations;
@dynamic projectUsers;
@dynamic projectObservationRuleTerms;
@dynamic projectObservationFields;
@dynamic featuredAt;
@dynamic latitude;
@dynamic longitude;
@dynamic group;
@dynamic newsItemCount;

+ (RKManagedObjectMapping *)mapping
{
    if (!defaultMapping) {
        defaultMapping = [RKManagedObjectMapping mappingForClass:[self class] inManagedObjectStore:[RKManagedObjectStore defaultObjectStore]];
        [defaultMapping mapKeyPathsToAttributes:
         @"id", @"recordID",
         @"created_at", @"createdAt",
         @"updated_at", @"updatedAt",
         @"title", @"title",
         @"cached_slug", @"cachedSlug",
         @"description", @"desc",
         @"icon_url", @"iconURL",
         @"project_type", @"projectType",
         @"terms", @"terms",
         @"project_observation_rule_terms", @"projectObservationRuleTerms",
         @"featured_at_utc", @"featuredAt",
         @"latitude", @"latitude",
         @"longitude", @"longitude",
         @"posts_count", @"newsItemCount",
         @"group", @"group",
         nil];
        [defaultMapping mapKeyPath:@"project_observation_fields" 
                    toRelationship:@"projectObservationFields" 
                       withMapping:[ProjectObservationField mapping]
                         serialize:NO];
        defaultMapping.primaryKeyAttribute = @"recordID";
    }
    return defaultMapping;
}

- (BOOL)observationsRestrictedToList
{
    NSArray *rules = [self.projectObservationRuleTerms componentsSeparatedByString:@"|"];
    for (NSString *rule in rules) {
        if ([rule isEqualToString:@"must be on list"]) {
            return YES;
        }
    }
    return NO;
}

- (NSArray *)sortedProjectObservationFields
{
//    return [[self.projectObservationFields allObjects] sortedArrayUsingSelector:@selector(position)];
    return [[self.projectObservationFields allObjects] sortedArrayUsingComparator:^NSComparisonResult(ProjectObservationField *obj1, ProjectObservationField *obj2) {
        return [obj1.position compare:obj2.position];
    }];
}

- (BOOL)isNewStyleProject {
    if ([self.projectType isEqualToString:@"collection"]) {
        return YES;
    } else if ([self.projectType isEqualToString:@"umbrella"]) {
        return YES;
    } else {
        return NO;
    }
}

- (NSString *)titleForTypeOfProject {
    if ([self.projectType isEqualToString:@"collection"]) {
        return NSLocalizedString(@"Collection Project", @"Collection type of project, which automatically collects observations into it.");
    } else if ([self.projectType isEqualToString:@"umbrella"]) {
        return NSLocalizedString(@"Umbrella Project", @"Umbrella type of project, which contains other projects within it.");
    } else {
        return NSLocalizedString(@"Traditional Project", @"Traditional inat type of project, where users have to manually add observations to the project.");
    }
}

@end
