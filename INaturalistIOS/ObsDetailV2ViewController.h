//
//  ObsDetailV2ViewController.h
//  iNaturalist
//
//  Created by Alex Shepard on 11/17/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ObservationVisualization.h"
#import "Uploadable.h"

@protocol ObservationOnlineEditingDelegate <NSObject>
- (void)editorCancelled;
- (void)editorEditedObservationOnline;
@end


@interface ObsDetailV2ViewController : UIViewController <ObservationOnlineEditingDelegate>

@property id <ObservationVisualization, Uploadable> observation;
@property NSInteger observationId;
@property BOOL shouldShowActivityOnLoad;

- (void)uploadFinished;

@end
