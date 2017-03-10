//
//  ObsDetailViewModelTests.m
//  iNaturalist
//
//  Created by Alex Shepard on 3/7/17.
//  Copyright © 2017 iNaturalist. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Mantle/Mantle.h>

#import "ObsDetailViewModel.h"
#import "ObsDetailInfoViewModel.h"
#import "ObsDetailActivityViewModel.h"
#import "ObsDetailFavesViewModel.h"
#import "ExploreObservation.h"
#import "MantleHelpers.h"
#import "DisclosureCell.h"
#import "ObsDetailTaxonCell.h"

@interface ObsDetailViewModelTests : XCTestCase
@property ObsDetailInfoViewModel *info;
@property ObsDetailActivityViewModel *activity;
@property ObsDetailFavesViewModel *faves;

@property UITableView *tv;
@end

@implementation ObsDetailViewModelTests

- (void)setUp {
    [super setUp];
    
    self.info = [[ObsDetailInfoViewModel alloc] init];
    self.activity = [[ObsDetailActivityViewModel alloc] init];
    self.faves = [[ObsDetailFavesViewModel alloc] init];
    
    self.tv = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    [self.tv registerNib:[UINib nibWithNibName:@"TaxonCell" bundle:nil]
  forCellReuseIdentifier:@"taxonFromNib"];
}

- (void)tearDown {
    [super tearDown];
}


- (void)testSectionCounts {
    // the number of info view model sections are computed based on the
    // properties of the backing observation.
    
    ExploreObservation *willet = [MantleHelpers willetFixture];
    self.info.observation = self.activity.observation = self.faves.observation = willet;
    XCTAssertEqual([self.info numberOfSectionsInTableView:self.tv], 4,
                   @"incorrect number of info sections for willet");
    XCTAssertEqual([self.activity numberOfSectionsInTableView:self.tv], 4,
                   @"incorrect number of activity sections for willet");
    XCTAssertEqual([self.faves numberOfSectionsInTableView:self.tv], 3,
                   @"incorrect number of faves sections for willet");
    
    
    ExploreObservation *polychaete = [MantleHelpers polychaeteFixture];
    self.info.observation = self.activity.observation = self.faves.observation = polychaete;
    XCTAssertEqual([self.info numberOfSectionsInTableView:self.tv], 4,
                   @"incorrect number of info sections for polychaete");
    XCTAssertEqual([self.activity numberOfSectionsInTableView:self.tv], 19,
                   @"incorrect number of activity sections for polychaete");
    XCTAssertEqual([self.faves numberOfSectionsInTableView:self.tv], 3,
                   @"incorrect number of faves sections for polychaete");
}

- (void)testActiveIdentifications {
    // inactive identifications have their Taxon row taxon name struck through.
    // active identifications do not.
    
    NSArray *activeTaxaIps = nil;
    NSArray *inactiveTaxaIps = nil;
    
    NSArray *fixtures = @[ [MantleHelpers willetFixture], [MantleHelpers polychaeteFixture] ];
    
    // the willet has two active identifications, no inactives
    // the polychaete has 6 active ids, 2 inactives
    
    NSArray *allActiveIps = @[
                              @[ @(2), @(3) ],                                  // willet
                              @[ @(6), @(7), @(8), @(10), @(12), @(18) ],       // polychaete
                              ];
    
    NSArray *allInactiveIps = @[
                                @[ ],                  // willet
                                @[ @(2), @(3) ],       // polychaete
                                ];
    
    for (int i = 0; i < fixtures.count; i++) {
        self.activity.observation = fixtures[i];

        NSArray *activeIps = allActiveIps[i];
        for (NSNumber *section in activeIps) {
            // taxa are always row 1 in a section
            NSIndexPath *ip = [NSIndexPath indexPathForRow:1 inSection:section.integerValue];
            ObsDetailTaxonCell *cell = (ObsDetailTaxonCell *)[self.activity tableView:self.tv cellForRowAtIndexPath:ip];
            XCTAssertTrue([cell isKindOfClass:[ObsDetailTaxonCell class]],
                          @"wrong kind of cell for taxon in identification");
            XCTAssertTrue([self taxonCellIsActive:cell],
                          @"cell at %@ should be active for %@",
                          ip, fixtures[i]);
        }
        
        NSArray *inactiveIps = allInactiveIps[i];
        for (NSNumber *section in inactiveIps) {
            // taxa are always row 1 in a section
            NSIndexPath *ip = [NSIndexPath indexPathForRow:1 inSection:section.integerValue];
            ObsDetailTaxonCell *cell = (ObsDetailTaxonCell *)[self.activity tableView:self.tv cellForRowAtIndexPath:ip];
            XCTAssertTrue([cell isKindOfClass:[ObsDetailTaxonCell class]],
                          @"wrong kind of cell for taxon in identification");
            XCTAssertFalse([self taxonCellIsActive:cell],
                           @"cell at %@ should be inactive for %@",
                           ip, fixtures[i]);
        }

    }
}

- (BOOL)taxonCellIsActive:(ObsDetailTaxonCell *)cell {
    NSRange taxonRange = NSMakeRange(0, cell.taxonNameLabel.text.length);
    NSDictionary *attrs = [cell.taxonNameLabel.attributedText attributesAtIndex:0 effectiveRange:&taxonRange];
    return !([attrs[NSStrikethroughStyleAttributeName] isEqual:@(NSUnderlineStyleSingle)]);
}



@end
