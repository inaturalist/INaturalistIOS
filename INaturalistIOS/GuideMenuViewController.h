//
//  GuideMenuViewController.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 9/19/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Guide.h"
#import "RXMLElement.h"
#import "RXMLElement+Helpers.h"

@protocol GuideMenuControllerDelegate <NSObject>
@optional
- (void)guideMenuControllerDidFilterByTag:(NSString *)tag;
- (RXMLElement *)guideMenuControllerXML;
@end

@interface GuideMenuViewController : UITableViewController
@property (nonatomic, strong) Guide *guide;
@property (nonatomic, weak) id <GuideMenuControllerDelegate> delegate;
@property (nonatomic, strong) RXMLElement *xml;
@property (nonatomic, strong) NSArray *tagNames;
@property (nonatomic, strong) NSDictionary *tagsByTagName;
@property (nonatomic, strong) NSString *guideDescription;
@property (nonatomic, strong) NSString *compiler;
@property (nonatomic, strong) NSString *license;
@end
