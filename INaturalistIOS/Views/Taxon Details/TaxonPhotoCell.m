//
//  TaxonPhotoCell.m
//  iNaturalist
//
//  Created by Alex Shepard on 3/9/16.
//  Copyright © 2016 iNaturalist. All rights reserved.
//

#import "TaxonPhotoCell.h"

@implementation TaxonPhotoCell

- (void)prepareForReuse {
    [super prepareForReuse];
    
    [self.creditsButton removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];
}

@end
