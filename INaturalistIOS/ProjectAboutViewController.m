//
//  ProjectAboutViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 3/22/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "ProjectAboutViewController.h"
#import "ProjectAboutInfoCell.h"
#import "NSString+Helpers.h"

@interface ProjectAboutViewController () {
    NSString *_titleText, *_aboutText;
}

@property (readonly) NSString *titleText;
@property (readonly) NSString *aboutText;

@property IBOutlet UILabel *titleLabel;
@property IBOutlet UITextView *aboutTextView;

@end

@implementation ProjectAboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"About this Project", @"about this project title");
    
    self.titleLabel.text = self.titleText;
    self.aboutTextView.text = self.aboutText;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [UIView animateWithDuration:0.3 animations:^{
        [self.navigationController.navigationBar setBackgroundImage:nil
                                                      forBarMetrics:UIBarMetricsDefault];
        self.navigationController.navigationBar.shadowImage = nil;
        self.navigationController.navigationBar.translucent = NO;
    }];
}

- (NSString *)titleText {
    if (!_titleText) {
        if (self.project.title.length == 0) {
            _titleText = NSLocalizedString(@"This project has no title.", nil);
        } else {
            _titleText = self.project.title;
        }
    }
    
    return _titleText;
}

- (NSString *)aboutText {
    if (!_aboutText) {
        if (self.project.inatDescription.length == 0) {
            _aboutText = NSLocalizedString(@"This project has no description.", nil);
        } else {
            // some projects embed HTML in their about text
            _aboutText = [self.project.inatDescription stringByStrippingHTML];
        }
    }
    
    return _aboutText;
}

@end
