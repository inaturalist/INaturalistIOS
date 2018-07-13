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
#import "ObservationAPI.h"

@interface UploadOperation : NSOperation
// we mostly upload to the node endpoint...
@property AFHTTPSessionManager *nodeSessionManager;
// but for a few things we need to talk to rails
@property AFHTTPSessionManager *railsSessionManager;
@property NSManagedObjectID *rootObjectId;
@property (weak) id <UploadManagerNotificationDelegate> delegate;

// subclasses will implement this to do their upload work
- (void)startUploadWork;

// subclasses will call this to safely mark the upload operation as finished
- (void)markOperationCompleted;
@end
