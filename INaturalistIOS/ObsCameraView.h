//
//  ObsCameraView.h
//  iNaturalist
//
//  Created by Alex Shepard on 2/24/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import "DBCameraView.h"

@interface ObsCameraView : DBCameraView
- (void)buildInterface;
- (void)buildInterfaceShowNoPhoto:(BOOL)showsNoPhoto;
@end
