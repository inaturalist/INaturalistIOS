//
//  UIImage+MapAnnotations.h
//  iNaturalist
//
//  Created by Alex Shepard on 8/21/19.
//  Copyright © 2019 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ObservationVisualization.h"

@interface UIImage (MapAnnotations)

+ (UIImage *)annotationImageForObservation:(id <ObservationVisualization>)observation;

@end
