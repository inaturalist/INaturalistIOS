//
//  UploadOperation.m
//  iNaturalist
//
//  Created by Alex Shepard on 6/20/18.
//  Copyright © 2018 iNaturalist. All rights reserved.
//

#import "UploadOperation.h"

@interface UploadOperation () {
    BOOL _is_executing;
    BOOL _is_finished;
}
@end

@implementation UploadOperation

- (instancetype)init {
    if (self = [super init]) {
        _is_executing = NO;
        _is_finished = NO;
    }
    
    return self;
}

- (void)start {
    if (!_is_executing) {
        // generate a KVO notoification for the executing path
        [self willChangeValueForKey:@"isExecuting"];
        @synchronized(self) {
            _is_executing = YES;
        }
        [self didChangeValueForKey:@"isExecuting"];
    }
    
    if (!self.cancelled) {
        [self startUploadWork];
    } else {
        [self markOperationCompleted];
    }
}

- (BOOL)isAsynchronous {
    return YES;
}

- (BOOL)isExecuting {
    @synchronized(self) {
        return _is_executing;
    }
}

- (BOOL)isFinished {
    @synchronized(self) {
        return _is_finished;
    }
}

- (void)markOperationCompleted {
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    @synchronized(self) {
        _is_executing = NO;
        _is_finished = YES;
    }
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (void)startUploadWork {
    // subclasses will implement this to do their upload work
}

@end
