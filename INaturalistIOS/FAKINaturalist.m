#import "FAKINaturalist.h"

@implementation FAKINaturalist

// Generated Code
+ (instancetype)inatWordmarkIconWithSize:(CGFloat)size { return [self iconWithCode:@"e" size:size]; }
+ (instancetype)arrowDownIconWithSize:(CGFloat)size { return [self iconWithCode:@"a" size:size]; }
+ (instancetype)arrowLeftIconWithSize:(CGFloat)size { return [self iconWithCode:@"b" size:size]; }
+ (instancetype)arrowRightIconWithSize:(CGFloat)size { return [self iconWithCode:@"c" size:size]; }
+ (instancetype)arrowUpIconWithSize:(CGFloat)size { return [self iconWithCode:@"d" size:size]; }
+ (instancetype)lifebuoyIconWithSize:(CGFloat)size { return [self iconWithCode:@"g" size:size]; }
+ (instancetype)speciesUnknownIconWithSize:(CGFloat)size { return [self iconWithCode:@"f" size:size]; }
+ (instancetype)iosCalendarOutlineIconWithSize:(CGFloat)size { return [self iconWithCode:@"h" size:size]; }
+ (instancetype)captiveIconWithSize:(CGFloat)size { return [self iconWithCode:@"i" size:size]; }

+ (NSDictionary *)allIcons {
    return @{
             @"e" : @"inatWordmark",
             @"a" : @"arrowDown",
             @"b" : @"arrowLeft",
             @"c" : @"arrowRight",
             @"d" : @"arrowUp",
             @"g" : @"lifebuoy",
             @"f" : @"speciesUnknown",
             @"h" : @"iosCalendarOutline",
             @"i" : @"captive",
             
             };
}

+ (UIFont *)iconFontWithSize:(CGFloat)size
{
#ifndef DISABLE_FONTAWESOME_AUTO_REGISTRATION
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self registerIconFontWithURL:[[NSBundle mainBundle] URLForResource:@"inaturalisticons" withExtension:@"ttf"]];
    });
#endif
    
    UIFont *font = [UIFont fontWithName:@"inaturalisticons" size:size];
    NSAssert(font, @"UIFont object should not be nil, check if the font file is added to the application bundle and you're using the correct font name.");
    return font;
}


@end