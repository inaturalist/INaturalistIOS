//
//  UploadOperation.h
//  iNaturalist
//
//  Created by Alex Shepard on 6/20/18.
//  Copyright © 2018 iNaturalist. All rights reserved.
//

@import AFNetworking;
@import CoreData;
@import Foundation;

#import "ObservationAPI.h"
#import "UploadManagerNotificationDelegate.h"

@interface UploadOperation : NSOperation
@property AFHTTPSessionManager *nodeSessionManager;
@property NSManagedObjectID *rootObjectId;
@property NSString *rootObjectUUID;
@property NSInteger userSiteId;
@property (weak) id <UploadManagerNotificationDelegate> delegate;

// subclasses will implement this to do their upload work
- (void)startUploadWork;

// subclasses will call this to safely mark the upload operation as finished
- (void)markOperationCompleted;
@end
