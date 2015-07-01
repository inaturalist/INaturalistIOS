//
//  UploadManager.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/20/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UploadManagerNotificationDelegate.h"

@class INatModel;

/**
 * Queue of INatModels to upload to the server. Ensures that records of each
 * model are fully * uploaded before moving on to the next model.
 */
@interface UploadManager : NSObject <RKObjectLoaderDelegate, RKRequestQueueDelegate, RKRequestDelegate>
- (id)initWithDelegate:(id)delegate;

/**
 * Add model to the queue, e.g. [sq addModel:Observation.class]
 */
- (void)addModel:(id)model;

/**
 * Add model to the queue with optional selector to fire on the delegate to
 * actually perform the upload operation. Useful for appending extra params like
 * file data.
 */
- (void)addModel:(id)model syncSelector:(SEL)syncSelector;
- (void)start;
- (void)stop;
- (BOOL)isRunning;
@end