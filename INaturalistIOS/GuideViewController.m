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

static NSString * const SWSegueRearIdentifier = @"sw_rear";
static NSString * const SWSegueFrontIdentifier = @"sw_front";
static NSString * const SWSegueRightIdentifier = @"sw_right";
// Override to set guide. Not too thrilled about this approach
- (void)prepareForSegue:(SWRevealViewControllerSegue *)segue sender:(id)sender
{
    NSString *identifier = segue.identifier;
    if ( [segue isKindOfClass:[SWRevealViewControllerSegue class]] && sender == nil )
    {
        if ( [identifier isEqualToString:SWSegueRearIdentifier] )
        {
            segue.performBlock = ^(SWRevealViewControllerSegue* rvc_segue, UIViewController* svc, UIViewController* dvc)
            {
                [self setRearViewController:dvc];
            };
        }
        else if ( [identifier isEqualToString:SWSegueFrontIdentifier] )
        {
            segue.performBlock = ^(SWRevealViewControllerSegue* rvc_segue, UIViewController* svc, UIViewController* dvc)
            {
                GuideCollectionViewController *vc = (GuideCollectionViewController *)dvc;
                vc.guide = self.guide;
                [self setFrontViewController:vc];
            };
        }
        else if ( [identifier isEqualToString:SWSegueRightIdentifier] )
        {
            segue.performBlock = ^(SWRevealViewControllerSegue* rvc_segue, UIViewController* svc, UIViewController* dvc)
            {
                GuideMenuViewController *vc = (GuideMenuViewController *)dvc;
                vc.delegate = (GuideCollectionViewController *)self.frontViewController;
                [self setRightViewController:dvc];
            };
        }
    }
}

- (IBAction)clickedGuideMenuButton:(id)sender {
    [self rightRevealToggleAnimated:YES];
}
- (void)viewDidUnload {
    [super viewDidUnload];
}
@end
