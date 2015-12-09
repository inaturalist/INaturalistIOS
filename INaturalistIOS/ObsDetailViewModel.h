//
//  ObsDetailViewModel.h
//  iNaturalist
//
//  Created by Alex Shepard on 11/17/15.
//  Copyright © 2015 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ObsDetailSection) {
    ObsDetailSectionInfo,
    ObsDetailSectionActivity,
    ObsDetailSectionFaves,
    ObsDetailSectionNone
};

@protocol ObsDetailViewModelDelegate <NSObject>
- (void)selectedSection:(ObsDetailSection)section;
- (ObsDetailSection)activeSection;
- (void)reloadObservation;
- (void)reloadRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)inat_performSegueWithIdentifier:(NSString *)identifier;
@end

@class Observation;

@interface ObsDetailViewModel : NSObject <UITableViewDataSource, UITableViewDelegate>

@property Observation *observation;
@property (assign) id <ObsDetailViewModelDelegate> delegate;
@property (readonly) ObsDetailSection sectionType;

@end
