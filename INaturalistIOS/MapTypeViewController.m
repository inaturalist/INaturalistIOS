//
//  MapTypeViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 3/7/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#import "MapTypeViewController.h"
#import <MapKit/MapKit.h>

@implementation MapTypeViewController

@synthesize mapTypeControl = _mapTypeControl;
@synthesize delegate = _delegate;
@synthesize mapType = _mapType;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.mapTypeControl.selectedSegmentIndex = self.mapType;
}


- (IBAction)choseMapType:(id)sender {
    UISegmentedControl *control = (UISegmentedControl *)sender;
    NSNumber *mapType;
    switch (control.selectedSegmentIndex) {
        case MKMapTypeSatellite:
            mapType = [NSNumber numberWithInt:MKMapTypeSatellite];
            break;
        case MKMapTypeHybrid:
            mapType = [NSNumber numberWithInt:MKMapTypeHybrid];
            break;            
        default:
            mapType = [NSNumber numberWithInt:MKMapTypeStandard];
            break;
    }
    if (self.delegate && [self.delegate respondsToSelector:@selector(mapTypeControllerDidChange:mapType:)]) {
        [self.delegate performSelector:@selector(mapTypeControllerDidChange:mapType:) 
                            withObject:self 
                            withObject:mapType];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
