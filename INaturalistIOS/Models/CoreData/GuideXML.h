//
//  GuideXML.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 9/23/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import "RXMLElement.h"

@interface GuideXML : RXMLElement
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *desc;
@property (nonatomic, strong) NSString *compiler;
@property (nonatomic, strong) NSString *license;
@property (nonatomic, strong) NSString *dirPath;
@property (nonatomic, strong) NSString *xmlPath;
@property (nonatomic, strong) NSString *xmlURL;
@property (nonatomic, strong) NSString *ngzPath;
@property (nonatomic, strong) NSString *ngzURL;
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) NSString *identifier;

+ (NSString *)dirPath;
+ (void)setupFilesystem;
- (id)initWithIdentifier:(NSString *)identifier;
- (GuideXML *)cloneWithXMLFilePath:(NSString *)path;
- (NSDate *)xmlDownloadedAt;
- (NSDate *)ngzDownloadedAt;
- (NSString *)imagePathForTaxonAtPosition:(NSInteger)position size:(NSString *)size fromXPath:(NSString *)xpath;
- (NSString *)imageURLForTaxonAtPosition:(NSInteger)position size:(NSString *)size fromXPath:(NSString *)xpath;
- (NSString *)displayNameForTaxonAtPosition:(NSInteger)position fromXpath:(NSString *)xpath;
- (NSString *)nameForTaxonAtPosition:(NSInteger)position fromXpath:(NSString *)xpath;
- (NSString *)ngzFileSize;
- (void)deleteNGZ;
@end
