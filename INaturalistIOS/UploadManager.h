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
@interface UploadManager : NSObject

@property (assign) BOOL cancelled;

- (id)initWithDelegate:(id)delegate;

- (void)uploadObservations:(NSArray *)observations completion:(void (^)())uploadCompletion;
- (void)uploadDeletes:(NSArray *)deletedRecords completion:(void (^)())deletesCompletion;

@end