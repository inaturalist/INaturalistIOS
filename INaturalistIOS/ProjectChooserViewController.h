//
//  ProjectChooserViewController.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/16/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ProjectChooserViewController;

@protocol ProjectChooserViewControllerDelegate <NSObject>
@optional
- (void)projectChooserViewControllerDidCancel:(ProjectChooserViewController *)controller;
- (void)projectChooserViewController:(ProjectChooserViewController *)controller 
                       choseProjects:(NSArray *)projects;
@end

@interface ProjectChooserViewController : UITableViewController <RKObjectLoaderDelegate>
@property (weak, nonatomic) UIViewController *delegate;
@property (nonatomic, strong) NSArray *projectUsers;
@property (nonatomic, strong) NSMutableArray *chosenProjects;
@property (nonatomic, strong) UILabel *noContentLabel;
@property (nonatomic, strong) RKObjectLoader *loader;

- (IBAction)clickedCancel:(id)sender;
- (IBAction)clickedDone:(id)sender;
- (void)loadData;
@end
