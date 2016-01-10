#import "FAKINaturalist.h"

@implementation FAKINaturalist

+ (instancetype)iconForIconicTaxon:(NSString *)iconicTaxon withSize:(CGFloat)size {
    if ([iconicTaxon isEqualToString:@"Animalia"]) { return [self iconicAnimaliaIconWithSize:size]; }
    if ([iconicTaxon isEqualToString:@"Arachnida"]) { return [self iconicArachnidaIconWithSize:size]; }
    if ([iconicTaxon isEqualToString:@"Aves"]) { return [self iconicAvesIconWithSize:size]; }
    if ([iconicTaxon isEqualToString:@"Actinopterygii"]) { return [self iconicActinopterygiiIconWithSize:size]; }
    if ([iconicTaxon isEqualToString:@"Reptilia"]) { return [self iconicReptiliaIconWithSize:size]; }
    if ([iconicTaxon isEqualToString:@"Protozoa"]) { return [self iconicProtozoaIconWithSize:size]; }
    if ([iconicTaxon isEqualToString:@"Plantae"]) { return [self iconicPlantaeIconWithSize:size]; }
    if ([iconicTaxon isEqualToString:@"Mollusca"]) { return [self iconicMolluscaIconWithSize:size]; }
    if ([iconicTaxon isEqualToString:@"Mammalia"]) { return [self iconicMammaliaIconWithSize:size]; }
    if ([iconicTaxon isEqualToString:@"Chromista"]) { return [self iconicChromistaIconWithSize:size]; }
    if ([iconicTaxon isEqualToString:@"Insecta"]) { return [self iconicInsectaIconWithSize:size]; }
    if ([iconicTaxon isEqualToString:@"Fungi"]) { return [self iconicFungiIconWithSize:size]; }
    if ([iconicTaxon isEqualToString:@"Amphibians"]) { return [self icnTaxaAmphibiansIconWithSize:size]; }

    // default to something
    return [self icnTaxaSomethingIconWithSize:size];
}

// Generated Code
+ (instancetype)inatWordmarkIconWithSize:(CGFloat)size { return [self iconWithCode:@"\ue000" size:size]; }
+ (instancetype)arrowDownIconWithSize:(CGFloat)size { return [self iconWithCode:@"\ue001" size:size]; }
+ (instancetype)arrowLeftIconWithSize:(CGFloat)size { return [self iconWithCode:@"\ue002" size:size]; }
+ (instancetype)arrowRightIconWithSize:(CGFloat)size { return [self iconWithCode:@"\ue003" size:size]; }
+ (instancetype)speciesUnknownIconWithSize:(CGFloat)size { return [self iconWithCode:@"\ue004" size:size]; }
+ (instancetype)iosCalendarOutlineIconWithSize:(CGFloat)size { return [self iconWithCode:@"\ue005" size:size]; }
+ (instancetype)captiveIconWithSize:(CGFloat)size { return [self iconWithCode:@"\ue006" size:size]; }
+ (instancetype)chatbubbleIconWithSize:(CGFloat)size { return [self iconWithCode:@"\ue007" size:size]; }
+ (instancetype)identificationIconWithSize:(CGFloat)size { return [self iconWithCode:@"\ue008" size:size]; }
+ (instancetype)personIconWithSize:(CGFloat)size { return [self iconWithCode:@"\ue009" size:size]; }
+ (instancetype)iconicAnimaliaIconWithSize:(CGFloat)size { return [self iconWithCode:@"\ue00a" size:size]; }
+ (instancetype)iconicArachnidaIconWithSize:(CGFloat)size { return [self iconWithCode:@"\ue00b" size:size]; }
+ (instancetype)iconicAvesIconWithSize:(CGFloat)size { return [self iconWithCode:@"\ue00c" size:size]; }
+ (instancetype)iconicActinopterygiiIconWithSize:(CGFloat)size { return [self iconWithCode:@"\ue00d" size:size]; }
+ (instancetype)iconicReptiliaIconWithSize:(CGFloat)size { return [self iconWithCode:@"\ue00e" size:size]; }
+ (instancetype)iconicProtozoaIconWithSize:(CGFloat)size { return [self iconWithCode:@"\ue00f" size:size]; }
+ (instancetype)iconicPlantaeIconWithSize:(CGFloat)size { return [self iconWithCode:@"\ue010" size:size]; }
+ (instancetype)iconicMolluscaIconWithSize:(CGFloat)size { return [self iconWithCode:@"\ue011" size:size]; }
+ (instancetype)iconicMammaliaIconWithSize:(CGFloat)size { return [self iconWithCode:@"\ue012" size:size]; }
+ (instancetype)iconicChromistaIconWithSize:(CGFloat)size { return [self iconWithCode:@"\ue013" size:size]; }
+ (instancetype)iconicInsectaIconWithSize:(CGFloat)size { return [self iconWithCode:@"\ue014" size:size]; }
+ (instancetype)iconicFungiIconWithSize:(CGFloat)size { return [self iconWithCode:@"\ue015" size:size]; }
+ (instancetype)layersIconWithSize:(CGFloat)size { return [self iconWithCode:@"\ue016" size:size]; }
+ (instancetype)locateIconWithSize:(CGFloat)size { return [self iconWithCode:@"\ue017" size:size]; }
+ (instancetype)arrowsOutIconWithSize:(CGFloat)size { return [self iconWithCode:@"\ue018" size:size]; }
+ (instancetype)arrowsInIconWithSize:(CGFloat)size { return [self iconWithCode:@"\ue019" size:size]; }
+ (instancetype)icnTaxaSomethingIconWithSize:(CGFloat)size { return [self iconWithCode:@"\ue01a" size:size]; }
+ (instancetype)icnTaxaAmphibiansIconWithSize:(CGFloat)size { return [self iconWithCode:@"\ue01b" size:size]; }
+ (instancetype)icnIdHelpIconWithSize:(CGFloat)size { return [self iconWithCode:@"\ue01c" size:size]; }
+ (instancetype)noLocationIconWithSize:(CGFloat)size { return [self iconWithCode:@"\ue01d" size:size]; }
+ (instancetype)arrowUpIconWithSize:(CGFloat)size { return [self iconWithCode:@"\ue01e" size:size]; }
+ (instancetype)icnLocationObscuredIconWithSize:(CGFloat)size { return [self iconWithCode:@"\ue01f" size:size]; }
+ (instancetype)icnLocationPrivateIconWithSize:(CGFloat)size { return [self iconWithCode:@"\ue020" size:size]; }

+ (NSDictionary *)allIcons {
    return @{
             @"\ue000" : @"inatWordmark",
             @"\ue001" : @"arrowDown",
             @"\ue002" : @"arrowLeft",
             @"\ue003" : @"arrowRight",
             @"\ue004" : @"speciesUnknown",
             @"\ue005" : @"iosCalendarOutline",
             @"\ue006" : @"captive",
             @"\ue007" : @"chatbubble",
             @"\ue008" : @"identification",
             @"\ue009" : @"person",
             @"\ue00a" : @"iconicAnimalia",
             @"\ue00b" : @"iconicArachnida",
             @"\ue00c" : @"iconicAves",
             @"\ue00d" : @"iconicActinopterygii",
             @"\ue00e" : @"iconicReptilia",
             @"\ue00f" : @"iconicProtozoa",
             @"\ue010" : @"iconicPlantae",
             @"\ue011" : @"iconicMollusca",
             @"\ue012" : @"iconicMammalia",
             @"\ue013" : @"iconicChromista",
             @"\ue014" : @"iconicInsecta",
             @"\ue015" : @"iconicFungi",
             @"\ue016" : @"layers",
             @"\ue017" : @"locate",
             @"\ue018" : @"arrowsOut",
             @"\ue019" : @"arrowsIn",
             @"\ue01a" : @"icnTaxaSomething",
             @"\ue01b" : @"icnTaxaAmphibians",
             @"\ue01c" : @"icnIdHelp",
             @"\ue01d" : @"noLocation",
             @"\ue01e" : @"arrowUp",
             @"\ue01f" : @"icnLocationObscured",
             @"\ue020" : @"icnLocationPrivate",
             
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