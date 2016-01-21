//
//  NewsViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 1/13/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <SDWebImage/UIImageView+WebCache.h>
#import <FontAwesomeKit/FAKIonIcons.h>
#import <YLMoment/YLMoment.h>
#import <NSString_stripHtml/NSString_stripHTML.h>

#import "NewsViewController.h"
#import "ProjectPost.h"
#import "UIColor+INaturalist.h"
#import "Analytics.h"
#import "User.h"
#import "NewsitemViewController.h"
#import "ProjectPostCell.h"
#import "Project.h"
#import "UIColor+INaturalist.h"

static UIImage *briefcase;

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
        
        briefcase = ({
            FAKIcon *briefcaseOutline = [FAKIonIcons iosBriefcaseOutlineIconWithSize:35];
            [briefcaseOutline addAttribute:NSForegroundColorAttributeName value:[UIColor inatTint]];
            [briefcaseOutline imageWithSize:CGSizeMake(34, 45)];
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
    [self loadMyProjects];
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
    
    ProjectPostCell *cell = [tableView dequeueReusableCellWithIdentifier:@"projectPost"
                                                            forIndexPath:indexPath];
    
    ProjectPost *newsItem = [self.frc objectAtIndexPath:indexPath];
    
    // too much work to do in the main queue?
    NSFetchRequest *projectRequest = [Project fetchRequest];
    projectRequest.predicate = [NSPredicate predicateWithFormat:@"recordID == %@", newsItem.projectID];

    NSError *fetchError;
    Project *p = [[[Project managedObjectContext] executeFetchRequest:projectRequest
                                                                error:&fetchError] firstObject];
    if (fetchError) {
        [[Analytics sharedClient] debugLog:[NSString stringWithFormat:@"error fetching: %@",
                                            fetchError.localizedDescription]];
    } else if (p) {
        cell.projectName.text = p.title;
        NSURL *iconURL = [NSURL URLWithString:p.iconURL];
        if (iconURL) {
            [cell.projectImageView sd_setImageWithURL:iconURL];
        }
    } else {
        cell.projectImageView.image = briefcase;
    }
    
    // this is probably sloooooooow. too slow to do on
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *url = nil;
        NSString *htmlString = newsItem.body;
        NSScanner *theScanner = [NSScanner scannerWithString:htmlString];
        // find start of IMG tag
        [theScanner scanUpToString:@"<img" intoString:nil];
        if (![theScanner isAtEnd]) {
            [theScanner scanUpToString:@"src" intoString:nil];
            NSCharacterSet *charset = [NSCharacterSet characterSetWithCharactersInString:@"\"'"];
            [theScanner scanUpToCharactersFromSet:charset intoString:nil];
            [theScanner scanCharactersFromSet:charset intoString:nil];
            [theScanner scanUpToCharactersFromSet:charset intoString:&url];
            NSURL *imageURL = [NSURL URLWithString:url];
            if (imageURL) {
                [cell.postImageView sd_setImageWithURL:imageURL];
            }
        }
    });
    
    cell.postBody.text = newsItem.title;
    cell.postBody.text = [cell.postBody.text stringByAppendingString:@" - "];
    NSString *strippedBody = [[newsItem.body stringByStrippingHTML] stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    cell.postBody.text = [cell.postBody.text stringByAppendingString:strippedBody];
    cell.postedAt.text = [[YLMoment momentWithDate:newsItem.publishedAt] fromNow];
    
    [cell.actionButton addTarget:self
                          action:@selector(actionTapped:)
                forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}



- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    ProjectPost *newsItem = [self.frc objectAtIndexPath:indexPath];
    [self performSegueWithIdentifier:@"detail" sender:newsItem];
}

- (void)actionTapped:(UIControl *)control {
    [[[UIAlertView alloc] initWithTitle:@"Unimplemented"
                                message:@"Not yet implmeneted"
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil] show];
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


- (void)loadMyProjects {
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
