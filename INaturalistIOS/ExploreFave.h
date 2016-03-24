//
//  ExploreFave.h
//  iNaturalist
//
//  Created by Alex Shepard on 3/8/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "FaveVisualization.h"

@interface ExploreFave : NSObject <FaveVisualization>

@property (nonatomic, copy) NSString *faverName;
@property (nonatomic, assign) NSInteger faverId;
@property (nonatomic, copy) NSString *faverIconUrl;
@property (nonatomic, copy) NSDate *faveDate;

@end
