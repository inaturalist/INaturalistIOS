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
#define INatTokenPrefKey    @"INatTokenPrefKey"
#define kINatAuthServiceExtToken @"INatAuthServiceExtToken"
#define kINatAuthService @"INatAuthService"


#ifdef DEBUG
    #define INatBaseURL @"http://localhost:3000"
    #define INatMediaBaseURL @"http://127.0.0.1:3000"
#else
    #define INatBaseURL @"https://www.inaturalist.org"
    #define INatMediaBaseURL @"https://www.inaturalist.org"
#endif

#endif
