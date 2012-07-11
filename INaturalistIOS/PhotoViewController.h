//
//  PhotoViewController.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/22/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import <Three20/Three20.h>

@protocol PhotoViewControllerDelegate <NSObject>
- (void)photoViewControllerDeletePhoto:(id<TTPhoto>)photo;
@end

@interface PhotoViewController : TTPhotoViewController <UIActionSheetDelegate>
@property (nonatomic, strong) UIBarButtonItem *deleteButton;
@property (nonatomic, strong) id <PhotoViewControllerDelegate> delegate;

- (void)deletePhoto:(id)sender;
- (void)deleteCenterPhoto;
@end
