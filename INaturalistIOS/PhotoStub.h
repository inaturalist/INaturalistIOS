//
//  PhotoStub.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 7/9/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <Three20/Three20.h>

@interface PhotoStub : NSObject <TTPhoto>
@property (nonatomic, copy) NSString *url;

@property (nonatomic, assign) id<TTPhotoSource> photoSource;
@property (nonatomic, assign) int index;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, copy) NSString *caption;

- (id)initWithURL:(NSString *)theURL;

@end
