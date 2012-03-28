//
//  ProjectDetailViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/27/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "ProjectDetailViewController.h"

@implementation ProjectDetailViewController
@synthesize project = _project;
@synthesize sectionHeaderViews = _sectionHeaderViews;
@synthesize projectIcon = _projectIcon;
@synthesize projectTitle = _projectTitle;

#pragma mark - View lifecycle
- (void)viewDidLoad
{
    self.projectIcon.defaultImage = [UIImage imageNamed:@"projects.png"];
    self.projectIcon.urlPath = self.project.iconURL;
    self.projectTitle.text = self.project.title;
    
    CAGradientLayer *lyr = [CAGradientLayer layer];
    lyr.colors = [NSArray arrayWithObjects:
                  (id)[UIColor whiteColor].CGColor, 
                  (id)[UIColor colorWithRed:(220/255.0)  green:(220/255.0)  blue:(220/255.0)  alpha:1.0].CGColor, nil];
    lyr.locations = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0], [NSNumber numberWithFloat:1], nil];
    lyr.frame = self.tableView.tableHeaderView.bounds;
    [self.tableView.tableHeaderView.layer insertSublayer:lyr atIndex:0];
    [super viewDidLoad];
}

- (void)viewDidUnload {
    [self setProjectIcon:nil];
    [self setProjectTitle:nil];
    [super viewDidUnload];
}

#pragma mark - Table view delegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0 && indexPath.row == 0) {
        CGSize s = [self.project.desc sizeWithFont:[UIFont systemFontOfSize:16] 
                                           constrainedToSize:CGSizeMake(320, 1000) 
                                               lineBreakMode:UILineBreakModeWordWrap];
        return s.height + 10;
    } else if (indexPath.section == 1 && indexPath.row == 0) {
        CGSize s = [self.project.terms sizeWithFont:[UIFont systemFontOfSize:16] 
                                 constrainedToSize:CGSizeMake(320, 1000) 
                                     lineBreakMode:UILineBreakModeWordWrap];
        return s.height + 10;
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 30.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (!self.sectionHeaderViews) {
        self.sectionHeaderViews = [[NSMutableDictionary alloc] init];
    }
    NSNumber *key = [NSNumber numberWithInt:section];
    if ([self.sectionHeaderViews objectForKey:key]) {
        return [self.sectionHeaderViews objectForKey:key];
    }
    
    UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 30)];
    header.backgroundColor = [UIColor whiteColor];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 300, 20)];
    label.font = [UIFont boldSystemFontOfSize:17];
    label.textColor = [UIColor darkGrayColor];
    switch (section) {
        case 0:
            label.text = @"Description";
            break;
        case 1:
            label.text = @"Terms";
            break;
        default:
            break;
    }
    [header addSubview:label];
    
    [self.sectionHeaderViews setObject:header forKey:key];
    return header;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    TTStyledTextLabel *rowContent;
    if (indexPath.section == 0 && indexPath.row == 0) {
        rowContent = (TTStyledTextLabel *)[cell viewWithTag:1];
        NSLog(@"rowContent: %@", rowContent);
        if (!rowContent.text) {
            rowContent.text = [TTStyledText textFromXHTML:[NSString stringWithFormat:@"<div>%@</div>", self.project.desc]
                                              lineBreaks:NO 
                                                    URLs:YES];
            [rowContent sizeToFit];
            rowContent.backgroundColor = [UIColor whiteColor];
            NSLog(@"rowContent.text: %@", rowContent.text);
        }
    } else if (indexPath.section == 1 && indexPath.row == 0) {
        rowContent = (TTStyledTextLabel *)[cell viewWithTag:1];
        if (!rowContent.text) {
            rowContent.text = [TTStyledText textFromXHTML:[NSString stringWithFormat:@"<div>%@</div>", self.project.terms]
                                               lineBreaks:NO 
                                                     URLs:YES];
            [rowContent sizeToFit];
            rowContent.backgroundColor = [UIColor whiteColor];
        }
    }
    return cell;
}

#pragma mark - ScrollViewDelegate
// This is necessary to stop the section headers from sticking to the top of the screen
// http://stackoverflow.com/questions/664781/change-default-scrolling-behavior-of-uitableview-section-header
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat sectionHeaderHeight = 30;
    if (scrollView.contentOffset.y <= sectionHeaderHeight && scrollView.contentOffset.y >= 0) {
        scrollView.contentInset = UIEdgeInsetsMake(-scrollView.contentOffset.y, 0, 0, 0);
    } else if (scrollView.contentOffset.y>=sectionHeaderHeight) {
        scrollView.contentInset = UIEdgeInsetsMake(-sectionHeaderHeight, 0, 0, 0);
    }
}

- (IBAction)clickedViewButton:(id)sender {
    NSURL *url = [NSURL URLWithString:
                  [NSString stringWithFormat:@"%@/projects/%@", INatBaseURL, self.project.cachedSlug]];
    [[UIApplication sharedApplication] openURL:url];
}
@end
