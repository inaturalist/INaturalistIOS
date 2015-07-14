//
//  Analytics.m
//  iNaturalist
//
//  Created by Alex Shepard on 10/7/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <FlurrySDK/Flurry.h>
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
#ifdef INatFlurryKey
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[Analytics alloc] init];
        [Flurry startSession:INatFlurryKey];
        
#ifdef INatCrashlyticsKey
        [Fabric with:@[CrashlyticsKit]];
#endif

    });
#endif
    return _sharedClient;
}

- (void)event:(NSString *)name {
    [Flurry logEvent:name];
}

- (void)event:(NSString *)name withProperties:(NSDictionary *)properties {
    [Flurry logEvent:name withParameters:properties];
}

- (void)logAllPageViewForTarget:(UIViewController *)target {
    [Flurry logAllPageViewsForTarget:target];
}

- (void)timedEvent:(NSString *)name {
    [Flurry logEvent:name timed:YES];
}
- (void)timedEvent:(NSString *)name withProperties:(NSDictionary *)properties {
    [Flurry logEvent:name withParameters:properties timed:YES];
}

- (void)endTimedEvent:(NSString *)name {
    [Flurry endTimedEvent:name withParameters:nil];
}
- (void)endTimedEvent:(NSString *)name withProperties:(NSDictionary *)properties {
    [Flurry endTimedEvent:name withParameters:properties];
}

- (void)debugLog:(NSString *)logMessage {
#ifdef INatCrashlyticsKey
    CLS_LOG(@"%@", logMessage);
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

// settings
NSString *kAnalyticsEventSettingEnabled =                       @"Setting Enabled";
NSString *kAnalyticsEventSettingDisabled =                      @"Setting Disabled";
NSString *kAnalyticsEventSettingsNetworkChangeBegan =           @"Settings Network Change Began";
NSString *kAnalyticsEventSettingsNetworkChangeCompleted =       @"Settings Network Change Completed";

// guides
NSString *kAnalyticsEventDownloadGuideStarted =                 @"Guide Download - Start";
NSString *kAnalyticsEventDownloadGuideCompleted =               @"Guide Download - Complete";
NSString *kAnalyticsEventDeleteDownloadedGuide =                @"Guide Download - Delete";

