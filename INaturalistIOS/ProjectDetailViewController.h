//
//  ProjectDetailViewController.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/27/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Three20/Three20.h>
#import "Project.h"

@interface ProjectDetailViewController : UITableViewController
@property (nonatomic, strong) Project *project;
@property (nonatomic, strong) NSMutableDictionary *sectionHeaderViews;
@property (weak, nonatomic) IBOutlet TTImageView *projectIcon;
@property (weak, nonatomic) IBOutlet UILabel *projectTitle;
- (IBAction)clickedViewButton:(id)sender;
@end
