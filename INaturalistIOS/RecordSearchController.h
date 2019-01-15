//
//  RecordSearchController.h
//  
//
//  Created by Ken-ichi Ueda on 3/30/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <RestKit/RestKit.h>

@protocol RecordSearchControllerDelegate <NSObject>
@optional
- (void)recordSearchControllerSelectedRecord:(id)record;
- (void)recordSearchControllerClickedAccessoryForRecord:(id)record;
- (UITableViewCell *)recordSearchControllerCellForRecord:(NSObject *)record inTableView:(UITableView *)tableView;
@end

/**
 * Manages searches of RESTful records, querying remote records if possible.
 */
@interface RecordSearchController : NSObject <UITableViewDataSource, UITableViewDelegate, UISearchDisplayDelegate, UISearchBarDelegate, RKObjectLoaderDelegate>
@property (nonatomic, retain) NSMutableArray *searchResults;
@property (nonatomic, copy) NSString *savedSearchTerm;
@property (nonatomic, strong) UISearchDisplayController *searchDisplayController;
@property (nonatomic, strong) Class model;
@property (nonatomic, strong) NSString *searchURL;
@property (nonatomic, strong) NSTimer *requestTimer;
@property (nonatomic, strong) id <RecordSearchControllerDelegate> delegate;
@property (nonatomic, strong) UILabel *noContentLabel;
@property (nonatomic, assign) BOOL isLoading;
@property (nonatomic, assign) BOOL allowsFreeTextSelection;

- (id)initWithSearchDisplayController:(UISearchDisplayController *)searchDisplayController;
- (void)searchLocal:(NSString *)query;
- (void)searchRemote;
- (NSPredicate *)predicateForQuery:(NSString *)query;
@end
