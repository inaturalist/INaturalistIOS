//
//  INatSound.h
//  iNaturalist
//
//  Created by Alex Shepard on 2/3/21.
//  Copyright © 2021 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol INatSound <NSObject>

- (NSURL *)mediaUrl;
- (NSString *)mediaKey;

@end
