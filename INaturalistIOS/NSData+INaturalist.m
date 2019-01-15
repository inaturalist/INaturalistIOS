//
//  NSData+INaturalist.m
//  iNaturalist
//
//  Created by Alex Shepard on 10/23/17.
//  Copyright © 2017 iNaturalist. All rights reserved.
//

#import "NSData+INaturalist.h"

@implementation NSData (INaturalist)
- (NSDictionary * _Nullable)inat_gpsDictFromImageData {
    CGImageSourceRef source = nil;
    source = CGImageSourceCreateWithData((CFDataRef)self, NULL);
    if (!source) {
        return nil;
    }
    
    NSDictionary *metadata = (NSDictionary *) CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(source, 0, NULL));
    CFRelease(source);
    
    if (!metadata) {
        return nil;
    }
    
    return [metadata objectForKey:(NSString *)kCGImagePropertyGPSDictionary];
}
@end
