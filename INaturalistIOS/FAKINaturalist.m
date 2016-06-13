#import "FAKINaturalist.h"

@implementation FAKINaturalist

+ (instancetype)inatWordmarkIconWithSize:(CGFloat)size { return [self iconWithCode:@"a" size:size]; }

+ (NSDictionary *)allIcons {
    return @{
             @"a" : @"inatWordmark",
             
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