//
//  ProjectsSearchController.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/29/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//
//  With lots of help from 
//  http://clingingtoideas.blogspot.com/2010/02/uitableview-how-to-part-2-search.html

#import <Foundation/Foundation.h>

@interface ProjectsSearchController : NSObject <UITableViewDataSource, UITableViewDelegate, UISearchDisplayDelegate, UISearchBarDelegate, RKObjectLoaderDelegate>
@property (nonatomic, retain) NSMutableArray *searchResults;
@property (nonatomic, copy) NSString *savedSearchTerm;
@property (nonatomic, strong) UISearchDisplayController *searchDisplayController;

- (id)initWithSearchDisplayController:(UISearchDisplayController *)searchDisplayController;
- (void)searchLocal:(NSString *)query;
- (void)searchRemote:(NSString *)query;
@end
