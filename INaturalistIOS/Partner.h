//
//  Partner.h
//  iNaturalist
//
//  Created by Alex Shepard on 6/16/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Partner : NSObject

@property NSString *name;
// see https://www.itu.int/dms_pub/itu-t/opb/sp/T-SP-E.212A-2017-PDF-E.pdf
@property NSArray *mobileCountryCodes;
@property NSURL *baseURL;
@property NSInteger identifier;
@property UIImage *logo;
@property NSString *countryName;

@property NSString *shortName;

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryFromPlist;

@end
