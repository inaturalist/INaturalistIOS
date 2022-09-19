//
//  NSData+INaturalist.h
//  iNaturalist
//
//  Created by Alex Shepard on 10/23/17.
//  Copyright © 2017 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (INaturalist)
// returns nil if the data doesn't represent an image
// or if there's no GPS dict in EXIF
- (NSDictionary * _Nullable)inat_gpsDictFromImageData;
@end
