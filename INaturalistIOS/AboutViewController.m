//
//  AboutViewController.m
//  iNaturalist
//
//  Created by Alex Shepard on 6/13/18.
//  Copyright © 2018 iNaturalist. All rights reserved.
//

#import "AboutViewController.h"
#import "AboutHeaderView.h"

@interface AboutViewController ()

@end

@implementation AboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.sectionHeaderHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedSectionHeaderHeight = 25;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    AboutHeaderView *header = [AboutHeaderView fromXib];

    header.headerTitleLabel.text = @"iNaturalist is a joint initiative of the California Academy of Sciences and the National Geographic Society";
    
    header.headerBodyLabel.text = [NSString stringWithFormat:@"%@\n\n%@\n\n%@\n\n%@\n\n%@\n\n%@",
                                   NSLocalizedString(@"Credits", @"intro to credits section."),
                                   NSLocalizedString(@"iNaturalist is made by every single person who participates in our community. The people who build the software, maintain our infrastructure, and foster collaborations are Joelle Belmonte, Yaron Budowski, Tony Iwane, Patrick Leary, Scott Loarie, Carrie Seltzer, Alex Shepard, and Ken-ichi Ueda.", @"inat core team, alphabetically"),
                                   NSLocalizedString(@"Special thanks to NVIDIA and Visipedia for technical assistance with iNaturalist's computer vision suggestions.", @"vision assistance"),
                                   NSLocalizedString(@"iNaturalist uses Glyphish icons by Joseph Wain, ionicons by Ben Sperry, and icons by Luis Prado and Roman Shlyakov from the Noun Project. iNaturalist is also deeply grateful to the Cocoapods community, and to the contributions of our own open source community. See https://github.com/inaturalist/INaturalistIOS.", @"open source contributions"),
                                   NSLocalizedString(@"We are grateful for the translation assistance provided by the crowdin.com community, especially: Catherine B, Vladimir Belash, cgalindo, danieleseglie, Eduardo Martínez, naofum, Foss, jacquesboivin, Sungmin Ji, katunchik, NCAA, oarazy, sudachi, T.O, testamorta, and vilseskog. To join the iNaturalist iOS translation team, please visit https://crowdin.com/project/inaturalistios.", @"inat ios translators with more than 200 strings contributed, alphabetically"),
                                   @"IUCN category II places provided by IUCN and UNEP-WCMC (2015), The World Database on Protected Areas (WDPA) [On-line], [11/2014], Cambridge, UK: UNEP-WCMC. Available at: www.protectedplanet.net."];
    
    return header;
}

@end
