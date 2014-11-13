//
//  ExploreSearchView.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/12/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import "ExploreSearchView.h"
#import "ExploreActiveSearchView.h"
#import "ExploreSearchCompleteCell.h"
#import "ShortcutSearchItem.h"
#import "AutocompleteSearchItem.h"

#define SEARCH_AUTOCOMPLETE_CELL @"SearchAutocompleteCell"
#define SEARCH_SHORTCUT_CELL @"SearchShortcutCell"

@interface ExploreSearchView () <UITableViewDataSource,UITableViewDelegate,UISearchBarDelegate> {
    NSLayoutConstraint *optionsTableViewHeightConstraint;
    UIView *optionsContainerView;
    UITableView *optionsTableView;
    UISearchBar *optionsSearchBar;
}
@end

@implementation ExploreSearchView

-(instancetype)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        
        // set up the search ui
        optionsContainerView = ({
            UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
            view.translatesAutoresizingMaskIntoConstraints = NO;
            
            view.hidden = YES;
            view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5f];
            
            optionsSearchBar = ({
                UISearchBar *bar = [[UISearchBar alloc] initWithFrame:CGRectZero];
                bar.translatesAutoresizingMaskIntoConstraints = NO;
                
                bar.placeholder = @"Search";        // follow Apple mail example
                bar.delegate = self;
                
                bar;
            });
            [view addSubview:optionsSearchBar];
            
            optionsTableView = ({
                UITableView *tv = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
                tv.translatesAutoresizingMaskIntoConstraints = NO;
                
                tv.rowHeight = 44.0f;
                
                tv.dataSource = self;
                tv.delegate = self;
                
                [tv registerClass:[ExploreSearchCompleteCell class] forCellReuseIdentifier:SEARCH_AUTOCOMPLETE_CELL];
                [tv registerClass:[UITableViewCell class] forCellReuseIdentifier:SEARCH_SHORTCUT_CELL];
                
                tv;
            });
            [view addSubview:optionsTableView];
            
            view;
        });
        [self addSubview:optionsContainerView];
        
        self.activeSearchFilterView = ({
            ExploreActiveSearchView *view = [[ExploreActiveSearchView alloc] initWithFrame:CGRectZero];
            view.translatesAutoresizingMaskIntoConstraints = NO;
            
            view.hidden = YES;
            
            view;
        });
        [self insertSubview:self.activeSearchFilterView aboveSubview:optionsContainerView];
        
        NSDictionary *views = @{
                                @"optionsContainerView": optionsContainerView,
                                @"optionsSearchBar": optionsSearchBar,
                                @"optionsTableView": optionsTableView,
                                @"activeSearchFilterView": self.activeSearchFilterView,
                                };
        
        
        // Configure the Active Search UI
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[activeSearchFilterView]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[activeSearchFilterView]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        
        
        
        // Configure the Search Options UI
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[optionsContainerView]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[optionsContainerView]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[optionsSearchBar]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-0-[optionsTableView]-0-|"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[optionsSearchBar]-0-[optionsTableView]"
                                                                     options:0
                                                                     metrics:0
                                                                       views:views]];
        
        optionsTableViewHeightConstraint = [NSLayoutConstraint constraintWithItem:optionsTableView
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:nil
                                                                        attribute:NSLayoutAttributeNotAnAttribute
                                                                       multiplier:1.0f
                                                                         constant:0.0f];
        [self addConstraint:optionsTableViewHeightConstraint];
        
        
    }
    
    return self;
}

- (void)layoutIfNeeded {
    [optionsTableView reloadData];
    optionsTableViewHeightConstraint.constant = [self heightForTableView:optionsTableView
                                                           withRowHeight:optionsTableView.rowHeight];
    [self setNeedsUpdateConstraints];
    [super layoutIfNeeded];
}

#pragma mark - Helpers for showing/hiding different search capabilities

- (void)hideOptionSearch {
    // clear the search bar
    [optionsSearchBar resignFirstResponder];
    optionsSearchBar.text = @"";
    
    // re-layout the table view
    [optionsTableView reloadData];
    [self layoutIfNeeded];
    
    // hide the options container
    optionsContainerView.hidden = YES;
}

- (void)showOptionSearch {
    // start by hiding active search filter view
    [self hideActiveSearch];
    
    [self layoutIfNeeded];
    
    // show the options container
    optionsContainerView.hidden = NO;
}

- (BOOL)optionSearchIsActive {
    return !optionsContainerView.hidden;
}

- (void)hideActiveSearch {
    self.activeSearchFilterView.activeSearchLabel.text = @"";
    self.activeSearchFilterView.hidden = YES;
}

- (void)showActiveSearch {
    // hide option search
    [self hideOptionSearch];
    
    self.activeSearchFilterView.activeSearchLabel.text = [self.activeSearchTextDelegate activeSearchText];
    self.activeSearchFilterView.hidden = NO;
}

#pragma mark - tableview constraint helpers

- (CGFloat)heightForTableView:(UITableView *)tableView withRowHeight:(CGFloat)rowHeight {
    int numberOfRows = 0;
    for (int section = 0; section < tableView.numberOfSections; section++)
        for (int row = 0; row < [tableView numberOfRowsInSection:section]; row++)
            numberOfRows++;
    return rowHeight * numberOfRows;
}

#pragma mark - UISearchBar delegate

- (void)searchBar:(UISearchBar *)field textDidChange:(NSString *)searchText {
    [self layoutIfNeeded];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)field {
    // simulate tap on first row
    [optionsTableView.delegate tableView:optionsTableView
                 didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
}


#pragma mark - UITableView delegate/datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        // search auto-complete section: "find observers named alex" etc
        // only show when search text isn't empty
        if (optionsSearchBar.superview && ![optionsSearchBar.text isEqualToString:@""])
            return self.autocompleteItems.count;
        else
            return 0;
    } else {
        // search shortcut section: "find observations near me" etc
        // only show when search text is empty
        if ([optionsSearchBar.text isEqualToString:@""]) {
            return self.shortcutItems.count;
        } else {
            return 0;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        // autocomplete cells
        AutocompleteSearchItem *item = [self.autocompleteItems objectAtIndex:indexPath.row];
        item.action(optionsSearchBar.text);
    } else {
        // shortcut cells
        ShortcutSearchItem *item = [self.shortcutItems objectAtIndex:indexPath.row];
        item.action();
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        // autocomplete cells
        
        AutocompleteSearchItem *item = [self.autocompleteItems objectAtIndex:indexPath.row];
        ExploreSearchCompleteCell *cell = (ExploreSearchCompleteCell *)[tableView dequeueReusableCellWithIdentifier:SEARCH_AUTOCOMPLETE_CELL];
        // set the predicate first
        cell.predicate = item.predicate;
        cell.searchText = optionsSearchBar.text;
        
        return cell;
    } else {
        //shortcut cells
        
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:SEARCH_SHORTCUT_CELL];
        cell.textLabel.font = [UIFont italicSystemFontOfSize:14.0f];
        
        ShortcutSearchItem *item = [self.shortcutItems objectAtIndex:indexPath.row];
        cell.textLabel.text = item.title;
        return cell;
    }
}

-(UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.optionSearchIsActive && CGRectContainsPoint(optionsTableView.frame, point))
        return optionsTableView;
    
    if (self.optionSearchIsActive && CGRectContainsPoint(optionsSearchBar.frame, point))
        return optionsSearchBar;
    
    if (!self.optionSearchIsActive && !self.activeSearchFilterView.hidden && CGRectContainsPoint(self.activeSearchFilterView.removeActiveSearchButton.frame, point))
        return self.activeSearchFilterView.removeActiveSearchButton;
    
    return nil;
}

@end
