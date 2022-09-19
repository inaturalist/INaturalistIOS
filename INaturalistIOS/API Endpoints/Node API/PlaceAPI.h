//
//  PlaceAPI.h
//  iNaturalist
//
//  Created by Alex Shepard on 2/11/21.
//  Copyright © 2021 iNaturalist. All rights reserved.
//

#import "INatAPI.h"

@interface PlaceAPI : INatAPI

- (void)placesMatching:(NSString *)searchTerm handler:(INatAPIFetchCompletionCountHandler)done;

@end
