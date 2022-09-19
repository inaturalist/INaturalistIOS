//
//  ShortcutSearchItem.h
//  iNaturalist
//
//  Created by Alex Shepard on 11/12/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^ShortcutAction)(void);

@interface ShortcutSearchItem : NSObject

// shortcut items don't have user input text
// ie search near me or search mine
@property NSString *title;
@property (nonatomic, copy) ShortcutAction action;

+ (instancetype)itemWithTitle:(NSString *)title action:(ShortcutAction)action;

@end
