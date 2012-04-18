//
//  Project.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/12/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "Project.h"
#import "List.h"
#import "ProjectObservation.h"
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
@dynamic projectList;
@dynamic projectObservations;
@dynamic projectUsers;
@dynamic listID;
@dynamic projectObservationRuleTerms;
@dynamic featuredAt;
@dynamic latitude;
@dynamic longitude;

+ (RKManagedObjectMapping *)mapping
{
    if (!defaultMapping) {
        defaultMapping = [RKManagedObjectMapping mappingForClass:[self class]];
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
         @"project_list.id", @"listID",
         @"project_observation_rule_terms", @"projectObservationRuleTerms",
         @"featured_at_utc", @"featuredAt",
         @"rule_place.latitude", @"latitude",
         @"rule_place.longitude", @"longitude",
         nil];
        [defaultMapping mapKeyPath:@"project_list" 
                    toRelationship:@"projectList" 
                       withMapping:[List mapping]
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

@end
