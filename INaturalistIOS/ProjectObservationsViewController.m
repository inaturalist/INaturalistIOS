//
//  ProjectObservationViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 10/7/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>

#import "ProjectObservationsViewController.h"
#import "ProjectObservationHeaderView.h"
#import "ProjectObservation.h"
#import "Project.h"
#import "ProjectUser.h"
#import "Observation.h"
#import "Analytics.h"
#import "ProjectObservationField.h"
#import "ObservationField.h"

@interface ProjectObservationsViewController () <UITableViewDataSource, UITableViewDelegate, RKObjectLoaderDelegate, RKRequestDelegate>
@property UITableView *tableView;
@property RKObjectLoader *loader;
@end

@implementation ProjectObservationsViewController

#pragma mark - UIViewController lifecycle

- (void)viewDidLoad {
    self.tableView = ({
        UITableView *tv = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
        tv.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        
        tv.delegate = self;
        tv.dataSource = self;
        
        [tv registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
        
        tv;
    });
    
    [self.view addSubview:self.tableView];
    
    if ([[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSString *username = [defaults objectForKey:INatUsernamePrefKey];
        NSString *countryCode = [[NSLocale currentLocale] objectForKey: NSLocaleCountryCode];
        NSString *language = [[NSLocale preferredLanguages] objectAtIndex:0];
        NSString *url =[NSString stringWithFormat:@"/projects/user/%@.json?locale=%@-%@",
                        username,
                        language,
                        countryCode];
        
        if (username && username.length > 0) {
            [[Analytics sharedClient] debugLog:@"Network - Load projects for user"];
            RKObjectManager *objectManager = [RKObjectManager sharedManager];
            [objectManager loadObjectsAtResourcePath:url
                                          usingBlock:^(RKObjectLoader *loader) {
                                              loader.delegate = self;
                                              // handle naked array in JSON by explicitly directing the loader which mapping to use
                                              loader.objectMapping = [objectManager.mappingProvider objectMappingForClass:[ProjectUser class]];
                                          }];
        }
    }
}

#pragma mark - UITableView delegate & datasource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    [self configureCell:cell forIndexPath:indexPath];
    
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    Project *project = [self projectForSection:section];
    BOOL projectIsSelected = [self projectIsSelected:project];
    
    CGFloat height = [self tableView:tableView heightForHeaderInSection:section];
    ProjectObservationHeaderView *header = [[ProjectObservationHeaderView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, height)];
    
    header.projectTitleLabel.text = project.title;
    header.selectedSwitch.on = projectIsSelected;
    header.selectedSwitch.tag = section;
    [header.selectedSwitch addTarget:self action:@selector(selectedChanged:) forControlEvents:UIControlEventValueChanged];
    header.detailsLabel.hidden = !projectIsSelected || project.projectObservationFields.count == 0;
    
    NSURL *url = [NSURL URLWithString:project.iconURL];
    if (url) {
        [header.projectThumbnailImageView sd_setImageWithURL:url];
    }
    
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    Project *project = [self projectForSection:section];
    BOOL projectIsSelected = [self projectIsSelected:project];
    
    if (projectIsSelected && project.projectObservationFields.count > 0)
        return 66;
    else
        return 44;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    Project *project = [self projectForSection:section];
    if ([self projectIsSelected:project]) {
        return project.projectObservationFields.count;
    } else {
        return 0;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.joinedProjects.count;
}

#pragma mark - UITableView helpers

- (void)configureCell:(UITableViewCell *)cell forIndexPath:(NSIndexPath *)indexPath {
    Project *project = [self projectForSection:indexPath.section];
    ProjectObservationField *field = [project sortedProjectObservationFields][indexPath.item];
    cell.textLabel.text = field.observationField.name;
    cell.textLabel.textColor = [UIColor grayColor];
    cell.textLabel.font = [UIFont systemFontOfSize:12.0f];
    cell.textLabel.numberOfLines = 2;
    cell.indentationLevel = 2;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.2f];
    cell.accessoryView.backgroundColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.2f];
}

- (BOOL)projectIsSelected:(Project *)project {
    __block BOOL found = NO;
    [[[self.observation.projectObservations allObjects] copy] enumerateObjectsUsingBlock:^(ProjectObservation *po, NSUInteger idx, BOOL *stop) {
        if ([po.project isEqual:project]) {
            found = YES;
            *stop = YES;
        }
    }];
    return found;
}

- (Project *)projectForSection:(NSInteger)section {
    return [self.joinedProjects objectAtIndex:section];
}

- (void)selectedChanged:(UISwitch *)switcher {
    Project *project = [self projectForSection:switcher.tag];
    if (switcher.isOn) {
        ProjectObservation *po = [ProjectObservation object];
        po.observation = self.observation;
        po.project = project;
    } else {
        for (ProjectObservation *po in [self.observation.projectObservations copy]) {
            if ([po.project isEqual:project]) {
                [self.observation removeProjectObservationsObject:po];
                [po deleteEntity];
            }
        }
    }
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:switcher.tag]
                  withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - RKObjectLoaderDelegate

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects {
    NSDate *now = [NSDate date];
    for (INatModel *o in objects) {
        [o setSyncedAt:now];
    }
    
    if ([objectLoader.resourcePath rangeOfString:@"projects/user"].location != NSNotFound) {
        NSArray *rejects = [ProjectUser objectsWithPredicate:[NSPredicate predicateWithFormat:@"syncedAt < %@", now]];
        for (ProjectUser *pu in rejects) {
            [pu deleteEntity];
        }
    }
    
    NSError *error = nil;
    [[[RKObjectManager sharedManager] objectStore] save:&error];
    if (error) {
        [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"Objectstore Save Error: %@", error.localizedDescription]];
    }
    
    NSMutableArray *projects = [NSMutableArray array];
    [[ProjectUser all] enumerateObjectsUsingBlock:^(ProjectUser *pu, NSUInteger idx, BOOL *stop) {
        [projects addObject:pu.project];
    }];
    
    self.joinedProjects = [NSArray arrayWithArray:projects];
    
    [self.tableView reloadData];
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
    
    // was running into a bug in release build config where the object loader was
    // getting deallocated after handling an error.  This is a kludge.
    self.loader = objectLoader;
    
    NSString *errorMsg;
    bool jsonParsingError = false, authFailure = false;
    switch (objectLoader.response.statusCode) {
            // Unauthorized
        case 401:
            authFailure = true;
            // UNPROCESSABLE ENTITY
        case 422:
            errorMsg = NSLocalizedString(@"Unprocessable entity",nil);
            break;
        default:
            // KLUDGE!! RestKit doesn't seem to handle failed auth very well
            jsonParsingError = [error.domain isEqualToString:@"JKErrorDomain"] && error.code == -1;
            authFailure = [error.domain isEqualToString:@"NSURLErrorDomain"] && error.code == -1012;
            errorMsg = error.localizedDescription;
    }
}


@end
