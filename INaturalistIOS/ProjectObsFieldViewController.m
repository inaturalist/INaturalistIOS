//
//  ProjectObsFieldViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 10/13/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import "ProjectObsFieldViewController.h"
#import "ExploreProjectObsFieldRealm.h"
#import "ExploreObsFieldValueRealm.h"
#import "ExploreProjectRealm.h"

@interface ProjectObsFieldViewController () <UITableViewDataSource, UITableViewDelegate>
@property UITableView *tableView;
@end

@implementation ProjectObsFieldViewController

#pragma mark - UIViewController lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = self.pof.project.title;
    
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
    NSString *valueForRow = [self.pof.obsField.allowedValues objectAtIndex:indexPath.item];
    
    NSDictionary *attrs = @{
                            NSFontAttributeName: [UIFont systemFontOfSize:14],
                            };
    CGRect rect = [valueForRow boundingRectWithSize:CGSizeMake(self.view.bounds.size.width - 50, CGFLOAT_MAX)
                                            options:NSStringDrawingUsesLineFragmentOrigin
                                         attributes:attrs
                                            context:nil];
    
    return MAX(44, rect.size.height + 22);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.pof.obsField.allowedValues.count;
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
    RLMRealm *realm = [RLMRealm defaultRealm];
    [realm beginWriteTransaction];
    self.ofv.value = [self.pof.obsField.allowedValues objectAtIndex:selectedIndexPath.item];
    [realm commitWriteTransaction];
    
    // pop
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.pof.obsField.inatDescription ?: self.pof.obsField.name;
}

#pragma mark - UITableView helpers

- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    NSString *valueForRow = [self.pof.obsField.allowedValues objectAtIndex:indexPath.item];

    cell.textLabel.text = valueForRow;
    cell.textLabel.numberOfLines = 0;
    
    if ([valueForRow isEqualToString:self.ofv.value]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
}

@end
