//
//  ExploreProjectObsFieldRealm.m
//  iNaturalist
//
//  Created by Alex Shepard on 1/14/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

#import "ExploreProjectObsFieldRealm.h"
#import "ExploreProjectRealm.h"

@interface ExploreProjectObsFieldRealm ()
@property (readonly) RLMLinkingObjects *projects;
@end

@implementation ExploreProjectObsFieldRealm

- (instancetype)initWithMantleModel:(ExploreProjectObsField *)model {
    if (self = [super init]) {
        self.required = model.required;
        self.position = model.position;
        self.projectObsFieldId = model.projectObsFieldId;
        if (model.obsField) {
            self.obsField = [[ExploreObsFieldRealm alloc] initWithMantleModel:model.obsField];
        }
    }
    
    return self;
}

+ (NSDictionary *)valueForMantleModel:(ExploreProjectObsField *)mtlModel {
    NSMutableDictionary *value = [NSMutableDictionary dictionary];
    
    value[@"required"] = @(mtlModel.required);
    value[@"position"] = @(mtlModel.position);
    value[@"projectObsFieldId"] = @(mtlModel.projectObsFieldId);
    if (mtlModel.obsField) {
        value[@"obsField"] = [ExploreObsFieldRealm valueForMantleModel:mtlModel.obsField];
    }
    
    return [NSDictionary dictionaryWithDictionary:value];
}

+ (NSDictionary *)valueForCoreDataModel:(id)cdModel {
    NSMutableDictionary *value = [NSMutableDictionary dictionary];
    
    value[@"required"] = [cdModel valueForKey:@"required"];
    value[@"position"] = [cdModel valueForKey:@"position"];
    value[@"projectObsFieldId"] = [cdModel valueForKey:@"recordID"];
    if ([cdModel valueForKey:@"observationField"]) {
        value[@"obsField"] = [ExploreObsFieldRealm valueForCoreDataModel:[cdModel valueForKey:@"observationField"]];
    }
    
    return [NSDictionary dictionaryWithDictionary:value];
}

+ (NSString *)primaryKey {
    return @"projectObsFieldId";
}

+ (NSDictionary *)linkingObjectsProperties {
    return @{
        @"projects": [RLMPropertyDescriptor descriptorWithClass:ExploreProjectRealm.class
                                                   propertyName:@"projectObsFields"],
    };
}

- (ExploreProjectRealm *)project {
    // should only be one project attached to this linking object property
    return [self.projects firstObject];
}

@end
