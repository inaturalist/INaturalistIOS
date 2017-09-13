//
//  Analytics.m
//  iNaturalist
//
//  Created by Alex Shepard on 10/7/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import <Amplitude-iOS/Amplitude.h>

#import "Analytics.h"

@interface Analytics () <CrashlyticsDelegate>
@end

@implementation Analytics

+ (Analytics *)sharedClient {
    static Analytics *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[Analytics alloc] init];

#ifdef INatCrashlyticsKey
        [Fabric with:@[CrashlyticsKit]];
#endif
        
#ifdef INatAmplitudeKey
        [[Amplitude instance] initializeApiKey:INatAmplitudeKey];
#endif
    });
    return _sharedClient;
}

- (void)logMetric:(NSString *)metricName value:(NSNumber *)metricValue {
    [self event:metricName withProperties:@{ @"Amount": metricValue }];
}

- (void)event:(NSString *)name {
#ifdef INatCrashlyticsKey
    [Answers logCustomEventWithName:name customAttributes:nil];
#endif
    
#ifdef INatAmplitudeKey
    [[Amplitude instance] logEvent:name];
#endif
}

- (void)event:(NSString *)name withProperties:(NSDictionary *)properties {
#ifdef INatCrashlyticsKey
    [Answers logCustomEventWithName:name customAttributes:properties];
#endif
    
#ifdef INatAmplitudeKey
    [[Amplitude instance] logEvent:name withEventProperties:properties];
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

NSString *kAnalyticsEventNavigateObservationDetail =            @"Navigate - Observations - Details";

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

// observation activities
NSString *kAnalyticsEventCreateObservation =                    @"Create Observation";
NSString *kAnalyticsEventSyncObservation =                      @"Sync Observation";
NSString *kAnalyticsEventSyncStopped =                          @"Sync Stopped";
NSString *kAnalyticsEventSyncFailed =                           @"Sync Failed";

// login
NSString *kAnalyticsEventLogin =                                @"Login";
NSString *kAnalyticsEventLoginFailed =                          @"Login Failed";
NSString *kAnalyticsEventSignup =                               @"Create Account";
NSString *kAnalyticsEventLogout =                               @"Logout";
NSString *kAnalyticsEventForgotPassword =                       @"Forgot Password";

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
NSString *kAnalyticsEventObservationAddIdentification =         @"Obs - Add Identification";

// view obs activities
NSString *kAnalyticsEventObservationShareStarted =              @"Obs - Share Started";
NSString *kAnalyticsEventObservationShareCancelled =            @"Obs - Share Cancelled";
NSString *kAnalyticsEventObservationShareFinished =             @"Obs - Share Finished";
NSString *kAnalyticsEventObservationFave =                      @"Obs - Fave";
NSString *kAnalyticsEventObservationUnfave =                    @"Obs - Unfave";
NSString *kAnalyticsEventObservationPhotoFailedToLoad =         @"Obs - Photo Failed to Load";

// settings
NSString *kAnalyticsEventSettingEnabled =                       @"Setting Enabled";
NSString *kAnalyticsEventSettingDisabled =                      @"Setting Disabled";
NSString *kAnalyticsEventSettingsNetworkChangeBegan =           @"Settings Network Change Began";
NSString *kAnalyticsEventSettingsNetworkChangeCompleted =       @"Settings Network Change Completed";
NSString *kAnalyticsEventProfilePhotoChanged = 					@"Profile Photo Changed";
NSString *kAnalyticsEventProfilePhotoRemoved = 					@"Profile Photo Removed";
NSString *kAnalyticsEventProfileLoginChanged =                  @"Profile Username Changed";


// news
NSString *kAnalyticsEventNewsOpenArticle =                      @"News - Open Article";
NSString *kAnalyticsEventNewsTapLink =                          @"News - Tap Link";
NSString *kAnalyticsEventNewsShareStarted =                     @"News - Share Started";
NSString *kAnalyticsEventNewsShareCancelled =                   @"News - Share Cancelled";
NSString *kAnalyticsEventNewsShareFinished =                    @"News - Share Finished";

// guides
NSString *kAnalyticsEventDownloadGuideStarted =                 @"Guide Download - Start";
NSString *kAnalyticsEventDownloadGuideCompleted =               @"Guide Download - Complete";
NSString *kAnalyticsEventDeleteDownloadedGuide =                @"Guide Download - Delete";

// background fetch
NSString *kAnalyticsEventBackgroundFetchFailed =                @"Background Fetch Failed";

// onboarding
NSString *kAnalyticsEventNavigateOnboardingScreenLogo =         @"Navigate - Onboarding - Logo";
NSString *kAnalyticsEventNavigateOnboardingScreenObserve =      @"Navigate - Onboarding - Observe";
NSString *kAnalyticsEventNavigateOnboardingScreenShare =        @"Navigate - Onboarding - Share";
NSString *kAnalyticsEventNavigateOnboardingScreenLearn =        @"Navigate - Onboarding - Learn";
NSString *kAnalyticsEventNavigateOnboardingScreenContribue =    @"Navigate - Onboarding - Contribute";
NSString *kAnalyticsEventNavigateOnboardingScreenLogin =        @"Navigate - Onboarding - Login";
NSString *kAnalyticsEventOnboardingLoginSkip =                  @"Onboarding Login Skip";
NSString *kAnalyticsEventOnboardingLoginCancel =                @"Onboarding Login Cancel";
NSString *kAnalyticsEventOnboardingLoginPressed =               @"Onboarding Login Action";

// permissions
NSString *kAnalyticsEventLocationPermissionsChanged =           @"Location Permissions Changed";
NSString *kAnalyticsEventCameraPermissionsChanged =             @"Camera Permissions Changed";
NSString *kAnalyticsEventPhotoLibraryPermissionsChanged =       @"Photo Library Permissions Changed";

// suggestions
NSString *kAnalyticsEventLoadTaxaSearch =                       @"Load Taxa Search";
NSString *kAnalyticsEventSuggestionsLoaded =                    @"Suggestions Loaded";
NSString *kAnalyticsEventSuggestionsFailed =                    @"Suggestions Failed to Load";
NSString *kAnalyticsEventChoseTaxon =                           @"User Chose Taxon";
NSString *kAnalyticsEventShowTaxonDetails =                     @"User Chose Taxon Details";
NSString *kAnalyticsEventSuggestionsImageGauge =                @"Suggestions API Call Time - Image";
NSString *kAnalyticsEventSuggestionsObservationGauge =          @"Suggestions API Call Time - Observation";

