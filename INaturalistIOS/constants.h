//
//  constants.h
//  iNaturalist
//
//  Created by Ken-ichi Ueda on 2/17/12.
//  Copyright (c) 2012 iNaturalist. All rights reserved.
//

#ifndef iNaturalist_constants_h
#define iNaturalist_constants_h

#define INatUsernamePrefKey @"INatUsernamePrefKey"
#define INatPasswordPrefKey @"INatPasswordPrefKey"
#ifdef DEBUG
    #define INatBaseURL @"http://localhost:3000"
    #define INatMediaBaseURL @"http://127.0.0.1:3000"
#else
    #define INatBaseURL @"http://www.inaturalist.org"
    #define INatMediaBaseURL @"http://up.inaturalist.org"
#endif

#endif
