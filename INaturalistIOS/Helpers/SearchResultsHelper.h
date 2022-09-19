//
//  SearchResultsHelper.h
//  iNaturalist
//
//  Created by Alex Shepard on 11/11/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SearchResultsHelper <NSObject>

@optional
@property (readonly) NSURL *searchResult_ThumbnailUrl;
@property (readonly) UIImage *searchResult_PlaceholderImage;

// attributedString options take priority
@property (readonly) NSString *searchResult_Title;
@property (readonly) NSAttributedString *searchResult_AttributedTitle;

@property (readonly) NSString *searchResult_SubTitle;
@property (readonly) NSAttributedString *searchResult_AttributedSubTitle;

@end
