//
//  GuideMenuViewController.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 9/19/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GuideXML.h"
#import "RXMLElement.h"
#import "RXMLElement+Helpers.h"

@protocol GuideMenuControllerDelegate <NSObject>
@optional
- (void)guideMenuControllerAddedFilterByTag:(NSString *)tag;
- (void)guideMenuControllerRemovedFilterByTag:(NSString *)tag;
- (GuideXML *)guideMenuControllerGuide;
- (void)guideMenuControllerGuideDownloadedNGZForGuide:(GuideXML *)guide;
- (void)guideMenuControllerGuideDeletedNGZForGuide:(GuideXML *)guide;
@end

@interface GuideMenuViewController : UITableViewController
@property (nonatomic, strong) GuideXML *guide;
@property (nonatomic, weak) id <GuideMenuControllerDelegate> delegate;
@property (nonatomic, strong) NSArray *tagPredicates;
@property (nonatomic, strong) NSDictionary *tagsByPredicate;
@property (nonatomic, strong) NSDictionary *tagCounts;

@property (nonatomic, strong) NSURLConnection *ngzDownloadConnection;
@property (nonatomic, strong) NSString *ngzFilePath;
@property (nonatomic, strong) UIProgressView *progress;
@property (nonatomic, strong) NSMutableData *receivedData;
@property (nonatomic) long expectedBytes;
@property (nonatomic) NSInteger lastStatusCode;

- (BOOL)isDownloading;
@end
