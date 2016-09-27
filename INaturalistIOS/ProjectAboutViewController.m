//
//  ProjectAboutViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 3/22/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "ProjectAboutViewController.h"
#import "Project.h"
#import "ProjectAboutInfoCell.h"
#import "NSString+Helpers.h"

@interface ProjectAboutViewController () {
    NSString *_titleText, *_aboutText, *_termsText;
    NSAttributedString *_rulesText;
}

@property (readonly) NSString *titleText;
@property (readonly) NSString *aboutText;
@property (readonly) NSString *termsText;
@property (readonly) NSAttributedString *rulesText;

@end

@implementation ProjectAboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"About this Project", @"about this project title");
    
    self.tableView.tableFooterView = [UIView new];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ProjectAboutInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:@"infoText" forIndexPath:indexPath];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (indexPath.section == 0) {
        cell.infoTextLabel.text = [self titleText];
    } else if (indexPath.section == 1) {
        cell.infoTextLabel.text = [self aboutText];
    } else if (indexPath.section == 2) {
        cell.infoTextLabel.text = [self termsText];
    } else if (indexPath.section == 3) {
        cell.infoTextLabel.attributedText = [self rulesText];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *text = @"";
    if (indexPath.section == 0) {
        return [ProjectAboutInfoCell heightForRowWithInfoText:[self titleText]
                                                  inTableView:tableView];
    } else if (indexPath.section == 1) {
        return [ProjectAboutInfoCell heightForRowWithInfoText:[self aboutText]
                                                  inTableView:tableView];
    } else if (indexPath.section == 2) {
        return [ProjectAboutInfoCell heightForRowWithInfoText:[self termsText]
                                                  inTableView:tableView];
    } else if (indexPath.section == 3) {
        return [ProjectAboutInfoCell heightForRowWithInfoAttributedText:[self rulesText]
                                                            inTableView:tableView];
    }

    return [ProjectAboutInfoCell heightForRowWithInfoText:text inTableView:tableView];
}

#pragma mark - Table vew delegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return NSLocalizedString(@"Title", @"project title header");
    } else if (section == 1) {
        return NSLocalizedString(@"About", @"about the project header");
    } else if (section == 2) {
        return NSLocalizedString(@"Terms", @"project terms header");
    } else if (section == 3) {
        return NSLocalizedString(@"Observation Rules", @"project observation rules header");
    } else if (section == 4) {
        return NSLocalizedString(@"Administrators", @"project admins header");
    } else {
        return nil;
    }
}

- (NSString *)titleText {
    if (!_titleText) {
        if (self.project.desc.length == 0) {
            _titleText = NSLocalizedString(@"This project has no title.", nil);
        } else {
            _titleText = self.project.title;
        }
    }
    
    return _titleText;
}

- (NSString *)aboutText {
    if (!_aboutText) {
        if (self.project.desc.length == 0) {
            _aboutText = NSLocalizedString(@"This project has no description.", nil);
        } else {
            // some projects embed HTML in their about text
            _aboutText = [self.project.desc stringByStrippingHTML];
        }
    }
    
    return _aboutText;
}


- (NSString *)termsText {
    if (!_termsText) {
        if (self.project.terms.length == 0) {
            _termsText = NSLocalizedString(@"This project has no terms.", nil);
        } else {
            // some projects embed HTML in their terms text
            _termsText = [self.project.terms stringByStrippingHTML];
        }
    }
    
    return _termsText;
}

- (NSAttributedString *)rulesText {
    if (!_rulesText) {
        if (self.project.projectObservationRuleTerms.length == 0) {
            NSString *noRules = NSLocalizedString(@"This project has no rules.", nil);
            _rulesText = [[NSAttributedString alloc] initWithString:noRules];
        } else {
            NSArray *rules = [self.project.projectObservationRuleTerms componentsSeparatedByString:@"|"];
            
            NSMutableString *string = [[NSMutableString alloc] init];
            for (int i = 0; i < rules.count; i++) {
                [string appendFormat:@"%ld. %@\n", (long)i+1, [rules[i] capitalizedString]];
            }
            
            NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:string];
            
            NSMutableParagraphStyle *paragrahStyle = [[NSMutableParagraphStyle alloc] init];
            [paragrahStyle setParagraphSpacing:4];
            [paragrahStyle setParagraphSpacingBefore:3];
            [paragrahStyle setFirstLineHeadIndent:0.0f];  // First line is the one with bullet point
            [paragrahStyle setHeadIndent:15];    // Set the indent for given bullet character and size font
            
            [attrString addAttributes:@{
                                        NSParagraphStyleAttributeName: paragrahStyle,
                                        NSFontAttributeName: [UIFont systemFontOfSize:14],
                                        }
                                range:NSMakeRange(0, [attrString length])];
            
            // non-mutable copy
            _rulesText = [[NSAttributedString alloc] initWithAttributedString:attrString];
        }
    }
    
    return _rulesText;
}


@end
