//
//  ProjectObsPhotoCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 2/23/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import <AFNetworking/UIImageView+AFNetworking.h>

#import "ProjectObsPhotoCell.h"

@implementation ProjectObsPhotoCell

- (void)prepareForReuse {
    self.photoImageView.image = nil;
    [self.photoImageView cancelImageRequestOperation];
    self.obsText.text = @"";
}

@end
