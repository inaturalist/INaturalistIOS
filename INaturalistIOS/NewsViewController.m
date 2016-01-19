//
//  NewsViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 1/13/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <FontAwesomeKit/FAKIonIcons.h>

#import "NewsViewController.h"
#import "ProjectPost.h"
#import "UIColor+INaturalist.h"
#import "Analytics.h"
#import "User.h"
#import "NewsitemViewController.h"

@interface NewsViewController () <NSFetchedResultsControllerDelegate, RKObjectLoaderDelegate, RKRequestDelegate> {
    NSFetchedResultsController *_frc;
}

@property (readonly) NSFetchedResultsController *frc;
@property RKObjectLoader *objectLoader;

@end

@implementation NewsViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        
        self.title = NSLocalizedString(@"News", nil);
        
        self.tabBarItem.image = ({
            FAKIcon *news = [FAKIonIcons iosListOutlineIconWithSize:35];
            [news addAttribute:NSForegroundColorAttributeName value:[UIColor inatInactiveGreyTint]];
            [[news imageWithSize:CGSizeMake(34, 45)] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        });
        
        self.tabBarItem.selectedImage = ({
            FAKIcon *news = [FAKIonIcons iosListIconWithSize:35];
            [news imageWithSize:CGSizeMake(34, 45)];
        });
        
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"newsItem"];
    
    NSError *err;
    [self.frc performFetch:&err];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // fetch stuff from the server
    [self loadRemoteNews];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"detail"]) {
        NewsItemViewController *vc = (NewsItemViewController *)[segue destinationViewController];
        vc.post = (ProjectPost *)sender;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.frc sections][0];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"newsItem" forIndexPath:indexPath];
    
    //NewsItem *item = [self.newsItems objectAtIndex:indexPath.item];
    ProjectPost *newsItem = [self.frc objectAtIndexPath:indexPath];
    
    cell.textLabel.text = newsItem.title;
    cell.detailTextLabel.text = newsItem.author.login;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ProjectPost *newsItem = [self.frc objectAtIndexPath:indexPath];
    [self performSegueWithIdentifier:@"detail" sender:newsItem];
}

- (void)loadRemoteNews {
    
    // silently do nothing if we're offline
    if (![[[RKClient sharedClient] reachabilityObserver] isNetworkReachable]) {
        return;
    }
    
    [[Analytics sharedClient] debugLog:@"Network - My Project Posts fetch"];
    [[RKObjectManager sharedManager] loadObjectsAtResourcePath:@"/posts/for_project_user.json"
                                                    usingBlock:^(RKObjectLoader *loader) {
                                                        loader.objectMapping = [ProjectPost mapping];
                                                        loader.delegate = self;
                                                    }];
}


#pragma mark - NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {
    
    switch (type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertRowsAtIndexPaths:@[ newIndexPath ]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:@[ indexPath ]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self.tableView reloadRowsAtIndexPaths:@[ indexPath ]
                                  withRowAnimation:UITableViewRowAnimationNone];
            break;
            
        case NSFetchedResultsChangeMove:
            [self.tableView moveRowAtIndexPath:indexPath
                                   toIndexPath:newIndexPath];
            break;
            
        default:
            break;
    }
}

#pragma mark - Fetched Results Controller helper

- (NSFetchedResultsController *)frc {
    
    if (!_frc) {
        // NSFetchedResultsController request for my observations
        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"ProjectPost"];
        
        // sort by common name, if available
        request.sortDescriptors = @[
                                    [[NSSortDescriptor alloc] initWithKey:@"publishedAt" ascending:NO],
                                    ];
        
        // setup our fetched results controller
        _frc = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                   managedObjectContext:[NSManagedObjectContext defaultContext]
                                                     sectionNameKeyPath:nil
                                                              cacheName:nil];
        
        // update our tableview based on changes in the fetched results
        _frc.delegate = self;
    }
    
    return _frc;
}

#pragma mark - RKObjectLoaderDelegate

- (void)objectLoader:(RKObjectLoader *)objectLoader didLoadObjects:(NSArray *)objects {

    NSError *error = nil;
    [[[RKObjectManager sharedManager] objectStore] save:&error];
    
    // check for new activity
    NSError *err;
    [self.frc performFetch:&err];
}

- (void)objectLoader:(RKObjectLoader *)objectLoader didFailWithError:(NSError *)error {
    // workaround an objectloader dealloc bug in restkit
    self.objectLoader = objectLoader;
    
    [[[UIAlertView alloc] initWithTitle:@"Error"
                                message:error.localizedDescription
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"OK",nil)
                      otherButtonTitles:nil] show];
}



@end
