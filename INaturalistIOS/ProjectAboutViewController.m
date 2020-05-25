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

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.0f;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ProjectAboutInfoCell *cell = [tableView dequeueReusableCellWithIdentifier:@"infoText" forIndexPath:indexPath];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (indexPath.section == 0) {
        if (self.project.title.length > 0) {
            cell.infoTextLabel.text = self.project.title;
        } else {
            cell.infoTextLabel.text = NSLocalizedString(@"This project has no title.", nil);
        }
    } else if (indexPath.section == 1) {
        if (self.project.inatDescription.length > 0) {
            cell.infoTextLabel.text = [self.project.inatDescription stringByStrippingHTML];
        } else {
            NSLocalizedString(@"This project has no description.", nil);
        }
    }
    
    return cell;
}

#pragma mark - Table vew delegate

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return NSLocalizedString(@"Title", @"project title header");
    } else if (section == 1) {
        return NSLocalizedString(@"About", @"about the project header");
    } else {
        return nil;
    }
}

@end
