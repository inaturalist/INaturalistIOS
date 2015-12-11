//
//  ProjectObsFieldViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 10/13/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import "ProjectObsFieldViewController.h"
#import "Project.h"
#import "ProjectObservationField.h"
#import "ObservationField.h"
#import "ObservationFieldValue.h"

@interface ProjectObsFieldViewController () <UITableViewDataSource, UITableViewDelegate>
@property UITableView *tableView;
@end

@implementation ProjectObsFieldViewController

#pragma mark - UIViewController lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = self.projectObsField.project.title;
    
    self.tableView = ({
        UITableView *tv = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        tv.translatesAutoresizingMaskIntoConstraints = NO;
        
        tv.delegate = self;
        tv.dataSource = self;
        [tv registerClass:[UITableViewCell class] forCellReuseIdentifier:@"row"];
        
        tv;
    });
    [self.view addSubview:self.tableView];
    
    NSDictionary *views = @{ @"tv": self.tableView };
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[tv]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[tv]-0-|"
                                                                      options:0
                                                                      metrics:0
                                                                        views:views]];

}

#pragma mark - UITableView datasource/delegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"row"];
    
    [self configureCell:cell forIndexPath:indexPath];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *value = self.projectObsField.observationField.allowedValuesArray[indexPath.item];
    
    NSDictionary *attrs = @{
                            NSFontAttributeName: [UIFont systemFontOfSize:14],
                            };
    CGRect rect = [value boundingRectWithSize:CGSizeMake(self.view.bounds.size.width - 50, CGFLOAT_MAX)
                                       options:NSStringDrawingUsesLineFragmentOrigin
                                    attributes:attrs
                                       context:nil];
    
    return MAX(44, rect.size.height + 22);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.projectObsField.observationField.allowedValuesArray.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)selectedIndexPath {
    // update selection
    for (NSIndexPath *indexPath in tableView.indexPathsForVisibleRows) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        if ([selectedIndexPath isEqual:indexPath]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        } else {
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }
    
    // update model
    self.obsFieldValue.value = self.projectObsField.observationField.allowedValuesArray[selectedIndexPath.item];
    
    // pop
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.projectObsField.observationField.desc ?: self.projectObsField.observationField.name;
}

#pragma mark - UITableView helpers

- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    NSString *value = self.projectObsField.observationField.allowedValuesArray[indexPath.item];
    cell.textLabel.text = value;
    cell.textLabel.numberOfLines = 0;
    
    if ([value isEqualToString:self.obsFieldValue.value]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

@end
