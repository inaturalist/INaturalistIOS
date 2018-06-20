//
//  UploadOperation.h
//  iNaturalist
//
//  Created by Alex Shepard on 6/20/18.
//  Copyright © 2018 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>
#import <RestKit/RestKit.h>

#import "UploadManagerNotificationDelegate.h"

@interface UploadOperation : NSOperation
@property AFHTTPSessionManager *sessionManager;
@property NSManagedObjectID *rootObjectId;
@property (weak) id <UploadManagerNotificationDelegate> delegate;

// children will implement this to do their upload work
- (void)startUploadWork;

// children will call this to safely mark the upload operation as finished
- (void)markOperationCompleted;
@end
