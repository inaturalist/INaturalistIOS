//
//  GolanProjectModel.h
//  iNaturalist
//
//  Created by hekepepper on 05/01/2016.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Project.h"

@interface GolanProjectModel : NSObject

@property (strong, nonatomic) Project *projectFromServer;
/**
 * The flag describes the selection's behaviour in observation screen.
 * 0 - not checked.
 * 1 - checked, user can change it.
 * 2 - checked, user can't change.
 */
@property (assign, nonatomic) NSInteger smartFlag;
@property (assign, nonatomic) NSInteger menuFlag;
@property (strong, nonatomic) NSNumber *projectID;

@end
