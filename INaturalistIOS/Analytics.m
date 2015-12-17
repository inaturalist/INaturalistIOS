//
//  Analytics.m
//  iNaturalist
//
//  Created by Alex Shepard on 10/7/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <Flurry-iOS-SDK/Flurry.h>
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

#import "Analytics.h"

@interface Analytics () <CrashlyticsDelegate> {
    
}
@end

@implementation Analytics

// without a flurry key, event logging is a no-op
+ (Analytics *)sharedClient {
    static Analytics *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[Analytics alloc] init];
#ifdef INatFlurryKey
        [Flurry startSession:INatFlurryKey];
#endif

#ifdef INatCrashlyticsKey
        [Fabric with:@[CrashlyticsKit]];
#endif
    });
    return _sharedClient;
}

- (void)event:(NSString *)name {
#ifdef INatFlurryKey
    [Flurry logEvent:name];
#endif
    
#ifdef INatCrashlyticsKey
    [Answers logCustomEventWithName:name customAttributes:nil];
#endif
}

- (void)event:(NSString *)name withProperties:(NSDictionary *)properties {
#ifdef INatFlurryKey
    [Flurry logEvent:name withParameters:properties];
#endif
    
#ifdef INatCrashlyticsKey
    [Answers logCustomEventWithName:name customAttributes:properties];
#endif
}

- (void)logAllPageViewForTarget:(UIViewController *)target {
#ifdef INatFlurryKey
    [Flurry logAllPageViewsForTarget:target];
#endif
}

- (void)timedEvent:(NSString *)name {
#ifdef INatFlurryKey
    [Flurry logEvent:name timed:YES];
#endif
}
- (void)timedEvent:(NSString *)name withProperties:(NSDictionary *)properties {
#ifdef INatFlurryKey
    [Flurry logEvent:name withParameters:properties timed:YES];
#endif
}

- (void)endTimedEvent:(NSString *)name {
#ifdef INatFlurryKey
    [Flurry endTimedEvent:name withParameters:nil];
#endif
}
- (void)endTimedEvent:(NSString *)name withProperties:(NSDictionary *)properties {
#ifdef INatFlurryKey
    [Flurry endTimedEvent:name withParameters:properties];
#endif
}

- (void)debugLog:(NSString *)logMessage {
#ifdef INatCrashlyticsKey
    CLS_LOG(@"%@", logMessage);
#endif
}

- (void)registerUserWithIdentifier:(NSString *)userIdentifier {
#ifdef INatCrashlyticsKey
    [[Crashlytics sharedInstance] setUserIdentifier:userIdentifier];
#endif
}

@end


#pragma mark Event Names For Analytics

NSString *kAnalyticsEventAppLaunch = @"AppLaunch";

// navigation
NSString *kAnalyticsEventNavigateExploreGrid =                  @"Explore - Navigate - Grid";
NSString *kAnalyticsEventNavigateExploreMap =                   @"Explore - Navigate - Map";
NSString *kAnalyticsEventNavigateExploreList =                  @"Explore - Navigate - List";
NSString *kAnalyticsEventNavigateExploreObsDetails =            @"Explore - Navigate - Obs Details";
NSString *kAnalyticsEventNavigateExploreTaxonDetails =          @"Explore - Navigate - Taxon Details";

NSString *kAnalyticsEventNavigateExploreLeaderboard =           @"Navigate - Explore - Leaderboard";

NSString *kAnalyticsEventNavigateGuides =                       @"Navigate - Guides - List";
NSString *kAnalyticsEventNavigateGuideCollection =              @"Navigate - Guides - Collection";
NSString *kAnalyticsEventNavigateGuideMenu =                    @"Navigate - Guides - Menu";
NSString *kAnalyticsEventNavigateGuideTaxon =                   @"Navigate - Guides - Taxon";
NSString *kAnalyticsEventNavigateGuidePhoto =                   @"Navigate - Guides - Photo";

NSString *kAnalyticsEventNavigateSettings =                     @"Navigate - Settings";
NSString *kAnalyticsEventNavigateTutorial =                     @"Navigate - Tutorial";
NSString *kAnalyticsEventNavigateLogin =                        @"Navigate - Login";
NSString *kAnalyticsEventNavigateSignup =                       @"Navigate - Signup";
NSString *kAnalyticsEventNavigateSignupSplash =                 @"Navigate - Signup Splash";
NSString *kAnalyticsEventNavigateAcknowledgements =             @"Navigate - Acknowledgements";

NSString *kAnalyticsEventNavigateMap =                          @"Navigate - Map";

NSString *kAnalyticsEventNavigateObservationActivity =          @"Navigate - Observations - Activity";
NSString *kAnalyticsEventNavigateObservationDetail =            @"Navigate - Observations - Details";
NSString *kAnalyticsEventNavigateObservations =                 @"Navigate - Observations - List";
NSString *kAnalyticsEventNavigatePhoto =                        @"Navigate - Observations - Photo";
NSString *kAnalyticsEventNavigateAddComment =                   @"Navigate - Observations - Add Comment";
NSString *kAnalyticsEventNavigateAddIdentification =            @"Navigate - Observations - Add Identification";
NSString *kAnalyticsEventNavigateEditLocation =                 @"Navigate - Observations - Edit Location";
NSString *kAnalyticsEventNavigateProjectChooser =               @"Navigate - Observations - Project Chooser";

NSString *kAnalyticsEventNavigateProjectDetail =                @"Navigate - Projects - Details";
NSString *kAnalyticsEventNavigateProjectList =                  @"Navigate - Projects - Listed Taxa";
NSString *kAnalyticsEventNavigateProjects =                     @"Navigate - Projects - List";

NSString *kAnalyticsEventNavigateTaxaSearch =                   @"Navigate - Taxa Search";
NSString *kAnalyticsEventNavigateTaxonDetails =                 @"Navigate - Taxon Details";


// search in explore
NSString *kAnalyticsEventExploreSearchPeople =                  @"Explore - Search - People";
NSString *kAnalyticsEventExploreSearchProjects =                @"Explore - Search - Projects";
NSString *kAnalyticsEventExploreSearchPlaces =                  @"Explore - Search - Places";
NSString *kAnalyticsEventExploreSearchCritters =                @"Explore - Search - Critters";
NSString *kAnalyticsEventExploreSearchNearMe =                  @"Explore - Search - Near Me";
NSString *kAnalyticsEventExploreSearchMine =                    @"Explore - Search - Mine";

// add comments & ids in explore
NSString *kAnalyticsEventExploreAddComment =                    @"Explore - Add Comment";
NSString *kAnalyticsEventExploreAddIdentification =             @"Explore - Add Identification";

// share in explore
NSString *kAnalyticsEventExploreObservationShare =              @"Explore - Observation - Share";

// observation activities
NSString *kAnalyticsEventCreateObservation =                    @"Create Observation";
NSString *kAnalyticsEventSyncObservation =                      @"Sync Observation";
NSString *kAnalyticsEventSyncStopped =                          @"Sync Stopped";
NSString *kAnalyticsEventSyncFailed =                           @"Sync Failed";
NSString *kAnalyticsEventSyncOneRecord =                        @"Sync One Record";
NSString *kAnalyticsEventObservationsPullToRefresh =            @"Pull to Refresh Observations";

// login
NSString *kAnalyticsEventLogin =                                @"Login";
NSString *kAnalyticsEventLoginFailed =                          @"Login Failed";
NSString *kAnalyticsEventSignup =                               @"Create Account";
NSString *kAnalyticsEventLogout =                               @"Logout";
NSString *kAnalyticsEventForgotPassword =                       @"Forgot Password";

// signup splash
NSString *kAnalyticsEventSplashFacebook =                       @"Splash Screen - Facebook";
NSString *kAnalyticsEventSplashGoogle =                         @"Splash Screen - Google";
NSString *kAnalyticsEventSplashSignupEmail =                    @"Splash Screen - Signup Email";
NSString *kAnalyticsEventSplashLogin =                          @"Splash Screen - Login";
NSString *kAnalyticsEventSplashCancel =                         @"Splash Screen - Cancel";
NSString *kAnalyticsEventSplashSkip =                           @"Splash Screen - Skip";

// partners
NSString *kAnalyticsEventPartnerAlertPresented =                @"Partner Alert Presented";
NSString *kAnalyticsEventPartnerAlertResponse =                 @"Partner Alert Response";

// model integrity
NSString *kAnalyticsEventObservationlessOFVSaved =              @"Observationless OFV Created";

// new observation flow
NSString *kAnalyticsEventNewObservationStart =                  @"New Obs - Start";
NSString *kAnalyticsEventNewObservationShutter =                @"New Obs - Shutter";
NSString *kAnalyticsEventNewObservationLibraryStart =           @"New Obs - Library Start";
NSString *kAnalyticsEventNewObservationLibraryPicked =          @"New Obs - Library Picked";
NSString *kAnalyticsEventNewObservationNoPhoto =                @"New Obs - No Photo";
NSString *kAnalyticsEventNewObservationCancel =                 @"New Obs - Cancel";
NSString *kAnalyticsEventNewObservationConfirmPhotos =          @"New Obs - Confirm Photos";
NSString *kAnalyticsEventNewObservationRetakePhotos =           @"New Obs - Retake Photos";
NSString *kAnalyticsEventNewObservationCategorizeTaxon =        @"New Obs - Categorize Taxon";
NSString *kAnalyticsEventNewObservationSkipCategorize =         @"New Obs - Skip Categorize";
NSString *kAnalyticsEventNewObservationSaveObservation =        @"New Obs - Save New Observation";

// observation edits
NSString *kAnalyticsEventObservationCaptiveChanged =            @"Obs - Captive Changed";
NSString *kAnalyticsEventObservationTaxonChanged =              @"Obs - Taxon Changed";
NSString *kAnalyticsEventObservationIDPleaseChanged =           @"Obs - ID Please Changed";
NSString *kAnalyticsEventObservationProjectsChanged =           @"Obs - Projects Changed";
NSString *kAnalyticsEventObservationGeoprivacyChanged =         @"Obs - Geoprivacy Changed";
NSString *kAnalyticsEventObservationNotesChanged =              @"Obs - Notes Changed";
NSString *kAnalyticsEventObservationDateChanged =               @"Obs - Date Changed";
NSString *kAnalyticsEventObservationLocationChanged =           @"Obs - Location Changed";
NSString *kAnalyticsEventObservationAddPhoto =                  @"Obs - Add Photo";
NSString *kAnalyticsEventObservationDeletePhoto =               @"Obs - Delete Photo";
NSString *kAnalyticsEventObservationNewDefaultPhoto =           @"Obs - New Default Photo";
NSString *kAnalyticsEventObservationViewHiresPhoto =            @"Obs - View Hires Photo";
NSString *kAnalyticsEventObservationDelete =                    @"Obs - Delete";

// settings
NSString *kAnalyticsEventSettingEnabled =                       @"Setting Enabled";
NSString *kAnalyticsEventSettingDisabled =                      @"Setting Disabled";
NSString *kAnalyticsEventSettingsNetworkChangeBegan =           @"Settings Network Change Began";
NSString *kAnalyticsEventSettingsNetworkChangeCompleted =       @"Settings Network Change Completed";

// guides
NSString *kAnalyticsEventDownloadGuideStarted =                 @"Guide Download - Start";
NSString *kAnalyticsEventDownloadGuideCompleted =               @"Guide Download - Complete";
NSString *kAnalyticsEventDeleteDownloadedGuide =                @"Guide Download - Delete";

