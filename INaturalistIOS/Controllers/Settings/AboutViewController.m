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
    
    self.title = NSLocalizedString(@"About", @"title of about screen");
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    AboutHeaderView *header = [AboutHeaderView fromXib];

    header.headerTitleLabel.text = NSLocalizedString(@"iNaturalist is a joint initiative of the California Academy of Sciences and the National Geographic Society", @"inat joint initiative statement");
    
    NSString *bodyText = [NSString stringWithFormat:@"%@\n\n",
                          NSLocalizedString(@"Credits",
                                            @"intro to credits section.")];
    bodyText = [bodyText stringByAppendingFormat:@"%@\n\n",
                NSLocalizedString(@"iNaturalist exists thanks to every single person who participates in our community. The people who build the software, design the interfaces, maintain our infrastructure, support the community, and foster collaborations are Yaron Budowski, Amanda Bullington, Tony Iwane, Johannes Klein, Patrick Leary, Scott Loarie, Abhas Misraraj, Carrie Seltzer, Alex Shepard, Angie Ta, and Ken-ichi Ueda.",
                                  @"inat core team, alphabetically")];
    bodyText = [bodyText stringByAppendingFormat:@"%@\n\n",
                NSLocalizedString(@"CalTech and Cornell Tech helped develop the computer vision system that suggests identifications from photographs. We thank Grant Van Horn, Serge Belongie, and Pietro Perona for advancing the computer vision research. More information can be found at visipedia.org. Special thanks to NVIDIA for additional assistance.",
                                  @"vision assistance")];
    bodyText = [bodyText stringByAppendingFormat:@"%@\n",
                NSLocalizedString(@"Argentina: Fundación Vida Silvestre Argentina supporting ArgentiNat (www.argentinat.org).",
                                  @"argentina partner")];
    bodyText = [bodyText stringByAppendingFormat:@"%@\n",
                NSLocalizedString(@"Australia: Atlas of Living Australia supporting iNaturalist Australia (inaturalist.ala.org.au/).",
                                  @"australia partner")];
    bodyText = [bodyText stringByAppendingFormat:@"%@\n",
                NSLocalizedString(@"Canada: Canadian Wildlife Federation, the Royal Ontario Museum, NatureServe Canada, and Parks Canada operating iNaturalist Canada (inaturalist.ca).",
                                  @"canada partner")];
    bodyText = [bodyText stringByAppendingFormat:@"%@\n",
                NSLocalizedString(@"Chile: Ministerio del Medio Ambiente supporting iNaturalist Chile (inaturalist.mma.gob.cl).",
                                  @"chile partner")];
    bodyText = [bodyText stringByAppendingFormat:@"%@\n",
                NSLocalizedString(@"Colombia: Instituto Humboldt operating Naturalista (colombia.inaturalist.org).",
                                  @"colombia partner")];
    bodyText = [bodyText stringByAppendingFormat:@"%@\n",
                NSLocalizedString(@"Ecuador: Instituto Nacional de Biodiversidad (INABIO) supporting iNaturalist Ecuador (ecuador.inaturalist.org).",
                                  @"ecuador partner")];
    bodyText = [bodyText stringByAppendingFormat:@"%@\n",
                NSLocalizedString(@"Finland: Finnish Museum of Natural History (Luomus) supporting iNaturalist Finland (https://inaturalist.laji.fi).",
                                  @"finland partner")];
    bodyText = [bodyText stringByAppendingFormat:@"%@\n",
                NSLocalizedString(@"Greece: iSea supporting iNaturalist Greece (greece.iNaturalist.org).",
                                  @"greece partner")];
    bodyText = [bodyText stringByAppendingFormat:@"%@\n",
                NSLocalizedString(@"Israel: University of Haifa supporting iNaturalist Israel (israel.inaturalist.org).",
                                  @"israel partner")];
    bodyText = [bodyText stringByAppendingFormat:@"%@\n",
                NSLocalizedString(@"Luxembourg: Luxembourg National Museum of Natural History (MnhnL) supporting iNaturalist Luxembourg (inaturalist.lu).",
                                  @"luxembourg partner")];
    bodyText = [bodyText stringByAppendingFormat:@"%@\n",
                NSLocalizedString(@"Mexico: Comisión nacional para el conocimiento y uso de la biodiversidad (CONABIO) operating NaturaLista (NaturaLista.mx).",
                                  @"mexico partner")];
    bodyText = [bodyText stringByAppendingFormat:@"%@\n",
                NSLocalizedString(@"New Zealand: New Zealand Biodiversity Recording Network operating iNaturalist NZ — Mātaki Taiao (inaturalist.nz).",
                                  @"nz partner")];
    bodyText = [bodyText stringByAppendingFormat:@"%@\n",
                NSLocalizedString(@"Panama: Ministerio de Ambiente operating iNaturalistPa (panama.inaturalist.org).",
                                  @"panama partner")];
    bodyText = [bodyText stringByAppendingFormat:@"%@\n\n",
                NSLocalizedString(@"Portugal: Associação Biodiversidade Para Todos operating Biodiversity4All (Biodiversity4All.org).",
                                  @"portugal partner")];
    
    bodyText = [bodyText stringByAppendingFormat:@"%@\n\n",
                NSLocalizedString(@"Taiwan: National Chiayi University and Taiwan Forestry Research Institute supporting iNaturalist Taiwan (taiwan.inaturalist.org).",
                                  @"taiwan partner")];

    bodyText = [bodyText stringByAppendingFormat:@"%@\n\n",
                NSLocalizedString(@"United Kingdom: National Biodiversity Network Trust supporting iNaturalist United Kingdom (uk.inaturalist.org).",
                                  @"uk partner")];
    
    bodyText = [bodyText stringByAppendingFormat:@"%@\n\n",
                NSLocalizedString(@"iNaturalist uses Glyphish icons by Joseph Wain, ionicons by Ben Sperry, and icons by Luis Prado and Roman Shlyakov from the Noun Project. iNaturalist is also deeply grateful to the Cocoapods community, and to the contributions of our own open source community. See https://github.com/inaturalist/INaturalistIOS.",
                                  @"open source contributions")];
    bodyText = [bodyText stringByAppendingFormat:@"%@\n\n",
                NSLocalizedString(@"We are grateful for the translation assistance provided by the crowdin.com community, especially: Catherine B, Vladimir Belash, cgalindo, danieleseglie, Eduardo Martínez, naofum, Foss, jacquesboivin, Sungmin Ji, katunchik, NCAA, oarazy, sudachi, T.O, testamorta, and vilseskog. To join the iNaturalist iOS translation team, please visit https://crowdin.com/project/inaturalistios.",
                                  @"inat ios translators with more than 200 strings contributed, alphabetically")];
    bodyText = [bodyText stringByAppendingFormat:@"%@",
                NSLocalizedString(@"IUCN category II places provided by IUCN and UNEP-WCMC (2015), The World Database on Protected Areas (WDPA) [On-line], [11/2014], Cambridge, UK: UNEP-WCMC. Available at: www.protectedplanet.net.",
                                  @"iucn places credit")];
    
    header.headerBodyLabel.text = bodyText;
    
    return header;
}

@end
