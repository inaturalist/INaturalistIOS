//
//  AboutViewModel.swift
//  iNaturalist
//
//  Created by Alex Shepard on 9/30/22.
//  Copyright © 2022 iNaturalist. All rights reserved.
//

// swiftlint:disable line_length

import Foundation

extension AboutView {
    class ViewModel: ObservableObject {
        let network = [
            "Argentina: Fundación Vida Silvestre Argentina supporting ArgentiNat (https://www.argentinat.org).",
            "Australia: Atlas of Living Australia supporting iNaturalist Australia (https://inaturalist.ala.org.au).",
            "Canada: Canadian Wildlife Federation, the Royal Ontario Museum, NatureServe Canada, and Parks Canada operating iNaturalist Canada (https://inaturalist.ca).",
            "Chile: Ministerio del Medio Ambiente supporting iNaturalist Chile (https://inaturalist.mma.gob.cl).",
            "Colombia: Instituto Humboldt operating Naturalista (https://colombia.inaturalist.org).",
            "Ecuador: Instituto Nacional de Biodiversidad (INABIO) supporting iNaturalist Ecuador (https://ecuador.inaturalist.org).",
            "Finland: Finnish Museum of Naturalist History (Luomus) supporting iNaturalist Finland (https://inaturalist.laji.fi)",
            "Greece: iSea supporting iNaturalist Greece (https://greece.inaturalist.org).",
            "Israel: University of Haifa supporting iNaturalist Israel (https://israel.inaturalist.org).",
            "Luxembourg: Luxembourg National Museum of Natural History (MnhnL) supporting iNaturalist Luxembourg (https://inaturalist.lu).",
            "Mexico: Comisión nacional para el conocimiento y uso de la biodiversidad (CONABIO) operating NaturaLista (https://naturalista.mx).",
            "New Zealand: New Zealand Biodiversity Recording Network operating iNaturalist NZ — Mātaki Taiao (https://inaturalist.nz)",
            "Panama: Ministerio de Ambiente operating iNaturalistPa (https://panama.inaturalist.org).",
            "Portugal: Associação Biodiversidade Para Todos operating Biodiversity4All (https://biodiversity4all.org).",
            "Taiwan: National Chiayi University and Taiwan Forestry Research Institute supporting iNaturalist Taiwan (https://taiwan.inaturalist.org).",
            "United Kingdom: National Biodiversity Network Trust supporting iNaturalist United Kingdom (https://uk.inaturalist.org)."
        ]

        let coreCredits = [
            "iNaturalist exists thanks to every single person who participates in our community. The people who build the software, design the interfaces, maintain our infrastructure, support the community, and foster collaborations are Yaron Budowski, Amanda Bullington, Tony Iwane, Patrick Leary, Scott Loarie, Abhas Misraraj, Carrie Seltzer, Alex Shepard, and Ken-ichi Ueda.",
            "CalTech and Cornell Tech helped develop the computer vision system that suggests identifications from photographs. We thank Grant Van Horn, Serge Belongie, and Pietro Perona for advancing the computer vision research. More information can be found at https://www.visipedia.org. Special thanks to NVIDIA for additional assistance."
        ]

        let otherAcknowledgements = [
            "iNaturalist uses Glyphish icons by Joseph Wain, ionicons by Ben Sperry, and icons by Luis Prado and Roman Shlyakov from the Noun Project. iNaturalist is also deeply grateful to the Cocoapods community, and to the contributions of our own open source community. See https://github.com/inaturalist/INaturalistIOS.",
            "We are grateful for the translation assistance provided by the crowdin.com community, especially: Catherine B, Vladimir Belash, cgalindo, danieleseglie, Eduardo Martínez, naofum, Foss, jacquesboivin, Sungmin Ji, katunchik, NCAA, oarazy, sudachi, T.O, testamorta, and vilseskog. To join the iNaturalist iOS translation team, please visit https://crowdin.com/project/inaturalistios.",
            "IUCN category II places provided by IUCN and UNEP-WCMC (2015), The World Database on Protected Areas (WDPA) [On-line], [11/2014], Cambridge, UK: UNEP-WCMC. Available at: www.protectedplanet.net."
        ]
    }
}
