//
//  ObsDetailViewModelTests.m
//  iNaturalist
//
//  Created by Alex Shepard on 3/7/17.
//  Copyright © 2017 iNaturalist. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "RKModelBaseTests.h"
#import "Observation.h"
#import "User.h"
#import "ObsDetailViewModel.h"
#import "DisclosureCell.h"

@interface ObsDetailViewModelTests : RKModelBaseTests
@property ObsDetailViewModel *viewModel;
@property UITableView *tableView;
@end

@implementation ObsDetailViewModelTests

- (void)setUp {
    [super setUp];
    
    self.viewModel = [[ObsDetailViewModel alloc] init];
    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero
                                                  style:UITableViewStylePlain];
    [self.tableView registerClass:[DisclosureCell class]
           forCellReuseIdentifier:@"disclosure"];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testUsernameCell {
    Observation *observation = [self observationForFixture:@"WilletObservation.json"];
    [self.viewModel setObservation:observation];

    // because of how the [observation username] call is implemented,
    // we need a user object here, too. sorry :(
    // this will generate an unused variable warning that we can safely ignore
    User *user __unused = [self userForObservationFixture:@"WilletObservation.json"];
    
    NSIndexPath *usernameIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    DisclosureCell *cell = (DisclosureCell *)[self.viewModel tableView:self.tableView
                                                 cellForRowAtIndexPath:usernameIndexPath];
    
    XCTAssertTrue([cell.titleLabel.text isEqualToString:@"alexshepard"],
                  @"wrong username text for username row of Willet Observation");
    
    // this assumes the test is being run in US locale
    XCTAssertTrue([cell.secondaryLabel.text isEqualToString:@"Jan 21, 2017"],
                  @"wrong date text for username row of Willet Observation");

}



- (Observation *)observationForFixture:(NSString *)fixtureFileName {
    id parsedJSON = [RKTestFixture parsedObjectWithContentsOfFixture:fixtureFileName];
    
    Observation *observation = [Observation createEntity];
    
    // this doesn't seem to be generating the cmplete object
    RKMappingTest *test = [RKMappingTest testForMapping:[Observation mapping]
                                           sourceObject:parsedJSON
                                      destinationObject:observation];
    @try {
        [test performMapping];
    } @catch (NSException *exception) {
        // restkit can throw spurious exceptions during taxon mappings
        // maybe isn't correctly mapping relationships?
        // do nothing
    }
    
    // pretend we awoke from CoreData
    // this is needed to compute some properties
    [observation awakeFromFetch];

    return observation;
}

- (User *)userForObservationFixture:(NSString *)fixtureFileName {
    id parsedJSON = [RKTestFixture parsedObjectWithContentsOfFixture:fixtureFileName];
    parsedJSON = [parsedJSON valueForKey:@"user"];
    
    User *user = [User createEntity];
    
    // this doesn't seem to be generating the cmplete object
    RKMappingTest *test = [RKMappingTest testForMapping:[User mapping]
                                           sourceObject:parsedJSON
                                      destinationObject:user];
    @try {
        [test performMapping];
    } @catch (NSException *exception) {
        // restkit can throw spurious exceptions during taxon mappings
        // maybe isn't correctly mapping relationships?
        // do nothing
    }
    
    return user;
}

                  


@end
