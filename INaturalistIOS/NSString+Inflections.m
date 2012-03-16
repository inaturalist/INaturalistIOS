//
//  NSString+Inflections.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/13/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "NSString+Inflections.h"

@implementation NSString (Inflections)

// Derived from code by Mathieu Godart, http://stackoverflow.com/a/4299110/720268
- (NSString *)underscore {
    NSScanner *scanner = [NSScanner scannerWithString:self];
    scanner.caseSensitive = YES;
    
    NSString *builder = [NSString string];
    NSString *buffer = nil;
    NSUInteger lastScanLocation = 0;
    
    while ([scanner isAtEnd] == NO) {
        
        if ([scanner scanCharactersFromSet:[NSCharacterSet lowercaseLetterCharacterSet] intoString:&buffer]) {
            builder = [builder stringByAppendingString:buffer];
        }
        
        if ([scanner scanCharactersFromSet:[NSCharacterSet uppercaseLetterCharacterSet] intoString:&buffer]) {
            if (scanner.scanLocation > 1) {
                builder = [builder stringByAppendingString:@"_"];
            }
            builder = [builder stringByAppendingString:[buffer lowercaseString]];
        }
        
        // If the scanner location has not moved, there's a problem somewhere.
        if (lastScanLocation == scanner.scanLocation) return self;
        lastScanLocation = scanner.scanLocation;
    }
    
    return builder;
}

+ (NSArray *)uncountableWords {
	static NSArray *_uncountableWords = nil;
    
	if (_uncountableWords == nil)
		_uncountableWords = [NSArray arrayWithObjects:
                             @"equipment",@"information",@"rice",@"money",@"species",@"series",
                             @"fish",@"sheep",@"jeans",@"moose",@"deer",nil];
    
	return _uncountableWords;
}

// obviously this is dumb.  Consider forking https://github.com/adamelliot/Inflections 
// and replacing RegexKitLite with NSRegularExpression
- (NSString *)pluralize
{
    if ([self.lowercaseString isEqualToString:@"taxon"] || [self.lowercaseString isEqualToString:@"listed_taxon"]) {
        return [self stringByReplacingOccurrencesOfString:@"axon" withString:@"axa"];
    } else {
        return [self stringByAppendingString:@"s"];
    }
}
@end
