//
//  ExploreDisambiguator.m
//  iNaturalist
//
//  Created by Alex Shepard on 11/11/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <AFNetworking/UIImageView+AFNetworking.h>

#import "ExploreDisambiguator.h"
#import "DisambiguationCell.h"
#import "SearchResultsHelper.h"

#define SEARCH_OPTION_CELL_ID @"SearchOptionCell"

@interface ExploreDisambiguator () {
    UIAlertView *alert;
    UITableView *optionsTableView;
    __block ExploreDisambiguator *strongSelf;
}

@end

@implementation ExploreDisambiguator

- (void)presentDisambiguationAlert {
    // hold a strong reference to self while the alert view is up
    // this is an intentional, temporary, retain cycle
    strongSelf = self;
    
    alert = [[UIAlertView alloc] initWithTitle:self.title
                                       message:self.message
                                      delegate:self
                             cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                             otherButtonTitles:nil];
    
    CGRect tableViewRect = CGRectMake(0, 0, 275.0f, 180.0f);
    
    optionsTableView = [[UITableView alloc] initWithFrame:tableViewRect
                                                                 style:UITableViewStylePlain];
    [optionsTableView registerClass:[DisambiguationCell class] forCellReuseIdentifier:SEARCH_OPTION_CELL_ID];
    optionsTableView.delegate = self;
    optionsTableView.dataSource = self;
    [alert setValue:optionsTableView
             forKey:@"accessoryView"];
    [alert show];
}

#pragma mark - UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    // release the retain cycle
    strongSelf = nil;
}

- (void)alertViewCancel:(UIAlertView *)alertView {
    // release the retain cycle
    strongSelf = nil;
}

#pragma mark - UITableView datasource/delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.searchOptions.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [alert dismissWithClickedButtonIndex:0 animated:YES];
    self.chosenBlock([self.searchOptions objectAtIndex:indexPath.item]);
    // release the retain cycle
    strongSelf = nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    id option = [self.searchOptions objectAtIndex:indexPath.row];
    
    DisambiguationCell *cell = (DisambiguationCell *)[tableView dequeueReusableCellWithIdentifier:SEARCH_OPTION_CELL_ID
                                                                                                 forIndexPath:indexPath];
    
    id <SearchResultsHelper> searchOption = (id <SearchResultsHelper>)option;
    
    // all of the SearchResultsHelper fields are optional
    // so we check if the option has implemented each of them before using it
    
    // prefer attributed title to title
    if ([searchOption respondsToSelector:@selector(searchResult_AttributedTitle)])
        cell.resultTitle.attributedText = [searchOption searchResult_AttributedTitle];
    else if ([searchOption respondsToSelector:@selector(searchResult_Title)])
        cell.resultTitle.text = [searchOption searchResult_Title];
    
    // prefer attributed subtitle to subtitle
    if ([searchOption respondsToSelector:@selector(searchResult_AttributedSubTitle)])
        cell.resultSubtitle.attributedText = [searchOption searchResult_AttributedSubTitle];
    else if ([searchOption respondsToSelector:@selector(searchResult_SubTitle)])
        cell.resultSubtitle.text = [searchOption searchResult_SubTitle];
    
    NSURL *thumbnailUrl = nil;
    if ([searchOption respondsToSelector:@selector(searchResult_ThumbnailUrl)])
        thumbnailUrl = [searchOption searchResult_ThumbnailUrl];
    
    UIImage *placeholderImage = nil;
    if ([searchOption respondsToSelector:@selector(searchResult_PlaceholderImage)])
        placeholderImage = [searchOption searchResult_PlaceholderImage];
    
    if (thumbnailUrl) {
        [cell.resultImageView setImageWithURL:thumbnailUrl
                             placeholderImage:placeholderImage];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44;
}



@end
