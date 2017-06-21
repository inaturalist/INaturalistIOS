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
#define INatLastDeletedSync @"INatLastDeletedSync"
#define kINatAuthServiceExtToken @"INatAuthServiceExtToken"
#define kINatAuthService @"INatAuthService"
#define kINatAutocompleteNamesPrefKey @"INatAutocompleteNamesPrefKey"
#define kInatCustomBaseURLStringKey @"InatCustomBaseURLStringKey"
#define kInatAutouploadPrefKey @"InatAutouploadPrefKey"
#define kINatUserIdPrefKey @"INatUserIdPrefKey"
#define kINatSuggestionsPrefKey @"INatSuggestionsPrefKey"

#define kINatLoggedInNotificationKey @"kINatLoggedInNotificationKey"

#ifdef DEBUG1
    #define INatBaseURL @"http://localhost:3000"
    #define INatMediaBaseURL @"http://127.0.0.1:3000"
    #define INatWebBaseURL @"http://127.0.0.1:3000"
#else
    // base URL for all API requests
    #define INatBaseURL @"https://www.inaturalist.org"

    // base URL for all media upload API requests
    #define INatMediaBaseURL @"https://www.inaturalist.org"

    // base URL for all website requests
    #define INatWebBaseURL @"http://www.inaturalist.org"
#endif

#endif
