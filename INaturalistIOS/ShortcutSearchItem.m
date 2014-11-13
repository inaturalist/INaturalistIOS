//
//  ShortcutSearchItem.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/12/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "ShortcutSearchItem.h"

@implementation ShortcutSearchItem

+ (instancetype)itemWithTitle:(NSString *)title action:(ShortcutAction)action {
    ShortcutSearchItem *item = [[ShortcutSearchItem alloc] init];
    item.title = title;
    item.action = action;
    return item;
}

@end
