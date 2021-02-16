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
    [super prepareForReuse];
    
    self.photoImageView.image = nil;
    [self.photoImageView cancelImageDownloadTask];
    self.obsText.text = @"";
    self.obsText.font = [UIFont italicSystemFontOfSize:self.obsText.font.pointSize];
}

@end
