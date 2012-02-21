//
//  ImageStore.m
//  INaturalistIOS
//
//  Created by Ken-ichi Ueda on 2/20/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
// 
//  Largely based on the ImageStore example in iOS Programming: The Big Nerd Range Guide, 
//  Second Edition by Joe Conway and Aaron Hillegass.
//

#import "ImageStore.h"

static ImageStore *sharedImageStore = nil;

@implementation ImageStore
@synthesize dictionary;

+ (id)allocWithZone:(NSZone *)zone
{
    return [self sharedImageStore];
}

+ (ImageStore *)sharedImageStore
{
    if (!sharedImageStore) {
        sharedImageStore = [[super allocWithZone:NULL] init];
    }
    return sharedImageStore;
}

- (id)init
{
    if (sharedImageStore) {
        return sharedImageStore;
    }
    self = [super init];
    if (self) {
        [self setDictionary:[[NSMutableDictionary alloc] init]];
    }
    return self;
}

- (UIImage *)find:(NSString *)key
{
    UIImage *image = [self.dictionary objectForKey:key];
    if (!image) {
        image = [UIImage imageWithContentsOfFile:[self pathForKey:key]];
        if (image) {
            [dictionary setValue:image forKey:key];
        } else {
            NSLog(@"Error: couldn't find image file for %@", key);
        }
    }
    return image;
}

- (void)store:(UIImage *)image forKey:(NSString *)key
{
    [self.dictionary setValue:image forKey:key];
    NSString *filePath = [self pathForKey:key];
    NSData *data = UIImageJPEGRepresentation(image, 0.8);
    [data writeToFile:filePath atomically:YES];
}

- (void)destroy:(NSString *)key
{
    if (!key) {
        return;
    }
    [self.dictionary removeObjectForKey:key];
    [[NSFileManager defaultManager] removeItemAtPath:[self pathForKey:key] error:NULL];
}

// http://stackoverflow.com/questions/8684551/generate-a-uuid-string-with-arc-enabled
- (NSString *)createKey
{
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    NSString *uuidStr = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, uuid);
    CFRelease(uuid);
    return uuidStr;
}

- (NSString *)pathForKey:(NSString *)key
{
    NSArray *docDirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docDir = [docDirs objectAtIndex:0];
    NSString *photoDirPath = [docDir stringByAppendingPathComponent:@"photos"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:photoDirPath]) {
        NSError *error;
        [[NSFileManager defaultManager] createDirectoryAtPath:photoDirPath 
                                  withIntermediateDirectories:YES 
                                                   attributes:nil 
                                                        error:&error];
    }
    return [NSString stringWithFormat:@"%@.jpg", [photoDirPath stringByAppendingPathComponent:key]];
}

@end
