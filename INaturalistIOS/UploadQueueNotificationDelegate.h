//
//  SyncNotificationDelegate.h
//  iNaturalist
//
//  Created by Alex Shepard on 6/30/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

@class INatModel;

@protocol UploadQueueNotificationDelegate <NSObject>
@optional
- (void)uploadSessionStartedTotal:(NSInteger)numberToUpload;
- (void)uploadSessionAuthRequired;
- (void)uploadSessionFinished;
- (void)uploadStartedFor:(INatModel *)object number:(NSInteger)number total:(NSInteger)total;
- (void)uploadSuccessFor:(INatModel *)object number:(NSInteger)number total:(NSInteger)total;
- (void)uploadFailedFor:(INatModel *)object error:(NSError *)error;
- (void)uploadTriggeredNonFatalError:(NSError *)error;
@end
