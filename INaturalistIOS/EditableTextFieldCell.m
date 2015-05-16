//
//  EditableTextViewCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 5/15/15.
//  Copyright (c) 2015 iNaturalist. All rights reserved.
//

#import "EditableTextFieldCell.h"

@implementation EditableTextFieldCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        self.textField = ({
            UITextField *tf = [[UITextField alloc] initWithFrame:self.bounds];
            tf.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
            
            tf;
        });
        [self.contentView addSubview:self.textField];
        
    }
    
    return self;
}

@end
