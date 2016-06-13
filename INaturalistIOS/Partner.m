//
//  Partner.m
//  iNaturalist
//
//  Created by Alex Shepard on 6/16/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import "Partner.h"

@implementation Partner

- (instancetype)initWithDictionary:(NSDictionary *)plistDict {
    if (self = [super init]) {
        
        NSString *baseUrlString = [plistDict valueForKey:@"baseUrl"];
        NSURL *url = [NSURL URLWithString:baseUrlString];
        if (url)
            self.baseURL = [url copy];
        else
            return nil;
        self.mobileCountryCodes = [plistDict valueForKey:@"mobileCountryCodes"];
        self.name = [plistDict valueForKey:@"name"];
        self.identifier = [[plistDict valueForKey:@"identifier"] integerValue];
        
        NSString *logoName = [plistDict valueForKey:@"logoName"];
        if (logoName) {
            self.logo = [UIImage imageNamed:logoName];
        }
        
        self.countryName = [plistDict valueForKey:@"countryName"];
    }
    
    return self;
}

- (BOOL)isEqual:(id)object {
    if (![object isKindOfClass:[Partner class]]) {
        return NO;
    }
    
    return self.identifier == ((Partner *)object).identifier;
}

@end
