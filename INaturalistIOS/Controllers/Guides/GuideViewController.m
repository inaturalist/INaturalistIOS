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

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    if (self.guide.title) {
        self.title = self.guide.title;
    }
    
    self.rightViewRevealWidth = UIScreen.mainScreen.bounds.size.width * 0.90;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSString *identifier = segue.identifier;
    if ([segue isKindOfClass:[PBRevealViewControllerSegueSetController class]] && sender == nil) {
        if ( [identifier isEqualToString:PBSegueMainIdentifier] ) {
            GuideCollectionViewController *vc = (GuideCollectionViewController *)segue.destinationViewController;
            vc.guide = self.guide;
        } else if ( [identifier isEqualToString:PBSegueRightIdentifier] ) {
            GuideMenuViewController *vc = (GuideMenuViewController *)segue.destinationViewController;
            vc.delegate = (GuideCollectionViewController *)self.mainViewController;
        }
    }
}

- (IBAction)clickedGuideMenuButton:(id)sender {
    [self revealRightView];
}

@end
