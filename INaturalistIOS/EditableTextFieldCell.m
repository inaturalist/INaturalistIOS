//
//  EditableTextViewCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 5/15/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import <BlocksKit/BlocksKit+UIKit.h>

#import "EditableTextFieldCell.h"

@interface EditableTextFieldCell () {
    NSAttributedString *_activeLeftAttributedString, *_inactiveLeftAttributedString;
}
@end

@implementation EditableTextFieldCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        self.textField = ({
            UITextField *tf = [[UITextField alloc] initWithFrame:self.bounds];
            tf.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
            
            tf.font = [UIFont systemFontOfSize:16.0f];
            
            tf;
        });
        [self.contentView addSubview:self.textField];
        
        UILabel *leftLabel = ({
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 60, 44)];
            
            label.textAlignment = NSTextAlignmentCenter;
            label.textColor = [UIColor whiteColor];
            
            label;
        });
        self.textField.leftView = leftLabel;
        
        [self configureLeftViewMode];
        
        __weak __typeof__(self) weakSelf = self;
        
        self.textField.bk_didBeginEditingBlock = ^(UITextField *tf) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            leftLabel.attributedText = strongSelf.activeLeftAttributedString;
        };
        
        self.textField.bk_didEndEditingBlock = ^(UITextField *tf) {
            __strong typeof(weakSelf)strongSelf = weakSelf;
            leftLabel.attributedText = strongSelf.inactiveLeftAttributedString;
        };
    }
    
    return self;
}

#pragma mark - Left Attr String setters/getters

- (void)setActiveLeftAttributedString:(NSAttributedString *)activeLeftAttributedString {
    if ([_activeLeftAttributedString isEqualToAttributedString:activeLeftAttributedString])
        return;
    
    _activeLeftAttributedString = activeLeftAttributedString;
    
    if ([self.textField isFirstResponder]) {
        ((UILabel *)self.textField.leftView).attributedText = _activeLeftAttributedString;
    }

    [self configureLeftViewMode];
}

- (NSAttributedString *)activeLeftAttributedString {
    return _activeLeftAttributedString;
}

- (void)setInactiveLeftAttributedString:(NSAttributedString *)inactiveLeftAttributedString {
    if ([_inactiveLeftAttributedString isEqualToAttributedString:inactiveLeftAttributedString])
        return;
    
    _inactiveLeftAttributedString = inactiveLeftAttributedString;
    
    if (![self.textField isFirstResponder]) {
        ((UILabel *)self.textField.leftView).attributedText = _inactiveLeftAttributedString;
    }
    
    [self configureLeftViewMode];
}

- (NSAttributedString *)inactiveLeftAttributedString {
    return _inactiveLeftAttributedString;
}

#pragma mark Left View Mode helper

- (void)configureLeftViewMode {
    // view mode is implied by presence of active/inactive left attr strings
    if (self.activeLeftAttributedString && self.inactiveLeftAttributedString) {
        self.textField.leftViewMode = UITextFieldViewModeAlways;
    } else if (self.activeLeftAttributedString) {
        self.textField.leftViewMode = UITextFieldViewModeWhileEditing;
    } else if (self.inactiveLeftAttributedString) {
        self.textField.leftViewMode = UITextFieldViewModeUnlessEditing;
    } else {
        self.textField.leftViewMode = UITextFieldViewModeNever;
    }
}

@end
