//
//  ProjectObservationField.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 9/12/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "ProjectObservationField.h"
#import "ObservationField.h"
#import "Project.h"

@implementation ProjectObservationField

@dynamic recordID;
@dynamic projectID;
@dynamic observationFieldID;
@dynamic required;
@dynamic position;
@dynamic createdAt;
@dynamic updatedAt;
@dynamic localCreatedAt;
@dynamic localUpdatedAt;
@dynamic syncedAt;
@dynamic project;
@dynamic observationField;


+ (NSArray *)textFieldDataTypes {
    return @[ @"text", @"dna" ];
}

@end
