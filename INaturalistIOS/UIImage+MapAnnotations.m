//
//  UIImage+MapAnnotations.m
//  iNaturalist
//
//  Created by Alex Shepard on 8/21/19.
//  Copyright © 2019 iNaturalist. All rights reserved.
//

#import <FontAwesomeKit/FontAwesomeKit.h>

#import "UIImage+MapAnnotations.h"
#import "UIColor+ExploreColors.h"

@implementation UIImage (MapAnnotations)

+ (UIImage *)annotationImageForObservation:(id <ObservationVisualization>)observation {
    if (observation.coordinatesObscuredToUser) {
        // style for iconic taxon of the observation
        
        FAKIcon *circle = [FAKIonIcons androidRadioButtonOffIconWithSize:25.0f];
        //FAKIcon *circle = [FAKIonIcons iosCircleOutlineIconWithSize:25.0f];
        [circle addAttribute:NSForegroundColorAttributeName value:[UIColor colorForIconicTaxon:observation.iconicTaxonName]];
        
        return [circle imageWithSize:CGSizeMake(25.0f, 25.0f)];
    } else {
        // style for iconic taxon of the observation
        FAKIcon *mapMarker = [FAKIonIcons iosLocationIconWithSize:25.0f];
        [mapMarker addAttribute:NSForegroundColorAttributeName value:[UIColor colorForIconicTaxon:observation.iconicTaxonName]];
        FAKIcon *mapOutline = [FAKIonIcons iosLocationOutlineIconWithSize:25.0f];
        [mapOutline addAttribute:NSForegroundColorAttributeName value:[[UIColor colorForIconicTaxon:observation.iconicTaxonName] darkerColor]];
        
        // offset the marker so that the point of the pin (rather than the center of the glyph) is at the location of the observation
        [mapMarker addAttribute:NSBaselineOffsetAttributeName value:@(25.0f)];
        [mapOutline addAttribute:NSBaselineOffsetAttributeName value:@(25.0f)];
        return [UIImage imageWithStackedIcons:@[mapMarker, mapOutline] imageSize:CGSizeMake(25.0f, 50.0f)];
    }
}


@end
