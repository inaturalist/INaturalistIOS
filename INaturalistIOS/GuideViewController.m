//
//  GuideContainerViewController.m
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 9/19/13.
//  Copyright (c) 2013 iNaturalist. All rights reserved.
//

#import "GuideViewController.h"
#import "GuideCollectionViewController.h"

@implementation GuideViewController

@synthesize guide = _guide;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    if (self.guide.title) {
        self.title = self.guide.title;
    }
}

- (void)prepareForSegue:(SWRevealViewControllerSegueSetController *)segue sender:(id)sender
{
    NSString *identifier = segue.identifier;
    if ( [segue isKindOfClass:[SWRevealViewControllerSegueSetController class]] && sender == nil ) {
        if ( [identifier isEqualToString:SWSegueFrontIdentifier] ) {
            GuideCollectionViewController *vc = (GuideCollectionViewController *)segue.destinationViewController;
            vc.guide = self.guide;
        } else if ( [identifier isEqualToString:SWSegueRightIdentifier] ) {
            GuideMenuViewController *vc = (GuideMenuViewController *)segue.destinationViewController;
            vc.delegate = (GuideCollectionViewController *)self.frontViewController;
        }
    }
}

- (IBAction)clickedGuideMenuButton:(id)sender {
    [self rightRevealToggleAnimated:YES];
}

@end
