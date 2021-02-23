//
//  Analytics.m
//  iNaturalist
//
//  Created by Alex Shepard on 10/7/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

@import Firebase;
@import FirebaseAnalytics;
@import FirebaseCrashlytics;

#import "Analytics.h"

@interface Analytics ()
@end

@implementation Analytics

+ (BOOL)canTrack {
    BOOL prefersNoTrack = [[NSUserDefaults standardUserDefaults] boolForKey:kINatPreferNoTrackPrefKey];
    if (prefersNoTrack) {
        return NO;
    } else {
        return YES;
    }
}

+ (void)disableCrashReporting {
    [[FIRCrashlytics crashlytics] setCrashlyticsCollectionEnabled:NO];
}

+ (void)enableCrashReporting {
    [[FIRCrashlytics crashlytics] setCrashlyticsCollectionEnabled:YES];
}

+ (Analytics *)sharedClient {
    static Analytics *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedClient = [[Analytics alloc] init];
        if ([Analytics canTrack]) {
            if (![FIRApp defaultApp]) {
                [FIRApp configure];
            }
            [[FIRCrashlytics crashlytics] setCrashlyticsCollectionEnabled:YES];
        }
    });
    return _sharedClient;
}

- (void)logMetric:(NSString *)metricName value:(NSNumber *)metricValue {
    if ([Analytics canTrack]) {
        [self event:metricName withProperties:@{ @"Amount": metricValue }];
    }
}

- (void)event:(NSString *)name {
    if ([Analytics canTrack] && [FIRApp defaultApp]) {
        [FIRAnalytics logEventWithName:name parameters:nil];
    }
}

- (void)event:(NSString *)name withProperties:(NSDictionary *)properties {
    if ([Analytics canTrack] && [FIRApp defaultApp]) {
        [FIRAnalytics logEventWithName:name parameters:properties];
    }
}

- (void)debugLog:(NSString *)logMessage {
    if ([Analytics canTrack] && [FIRApp defaultApp]) {
        [[FIRCrashlytics crashlytics] log:logMessage];
    }
}

- (void)debugError:(NSError *)error {
    if ([Analytics canTrack] && [FIRApp defaultApp]) {
        [[FIRCrashlytics crashlytics] recordError:error];
    }
}

- (void)registerUserWithIdentifier:(NSString *)userIdentifier {
    if ([Analytics canTrack] && [FIRApp defaultApp]) {
        [FIRAnalytics setUserID:userIdentifier];
        [[FIRCrashlytics crashlytics] setUserID:userIdentifier];
    }
}


@end


#pragma mark Event Names For Analytics

NSString *kAnalyticsEventAppLaunch = @"AppLaunch";

NSString *kAnalyticsEventNavigateObservationDetail =            @"Navigate_Observations_Details";

// search in explore
NSString *kAnalyticsEventExploreSearchPeople =                  @"Explore_Search_People";
NSString *kAnalyticsEventExploreSearchProjects =                @"Explore_Search_Projects";
NSString *kAnalyticsEventExploreSearchPlaces =                  @"Explore_Search_Places";
NSString *kAnalyticsEventExploreSearchCritters =                @"Explore_Search_Critters";
NSString *kAnalyticsEventExploreSearchNearMe =                  @"Explore_Search_Near_Me";
NSString *kAnalyticsEventExploreSearchMine =                    @"Explore_Search_Mine";

// add comments & ids in explore
NSString *kAnalyticsEventExploreAddComment =                    @"Explore_Add_Comment";
NSString *kAnalyticsEventExploreAddIdentification =             @"Explore_Add_Identification";

// observation activities
NSString *kAnalyticsEventCreateObservation =                    @"Create_Observation";
NSString *kAnalyticsEventSyncObservation =                      @"Sync_Observation";
NSString *kAnalyticsEventSyncStopped =                          @"Sync_Stopped";
NSString *kAnalyticsEventSyncFailed =                           @"Sync_Failed";

// login
NSString *kAnalyticsEventLogin =                                @"Login_Success";
NSString *kAnalyticsEventLoginFailed =                          @"Login_Failed";
NSString *kAnalyticsEventSignup =                               @"Create_Account";
NSString *kAnalyticsEventLogout =                               @"Logout";
NSString *kAnalyticsEventForgotPassword =                       @"Forgot_Password";

// partners
NSString *kAnalyticsEventPartnerAlertPresented =                @"Partner_Alert_Presented";
NSString *kAnalyticsEventPartnerAlertResponse =                 @"Partner_Alert_Response";

// model integrity
NSString *kAnalyticsEventObservationlessOFVSaved =              @"Observationles_OFV_Created";

// new observation flow

NSString *kAnalyticsEventNewObservationLibraryStart =           @"New_Obs_Start_Library";
NSString *kAnalyticsEventNewObservationCameraStart =            @"New_Obs_Start_Camera";
NSString *kAnalyticsEventNewObservationNoPhotoStart =           @"New_Obs_Start_No_Photo";
NSString *kAnalyticsEventNewObservationSoundRecordingStart =    @"New_Obs_Start_Sound_Record";

NSString *kAnalyticsEventNewObservationStart =                  @"New_Obs_Start";
NSString *kAnalyticsEventNewObservationShutter =                @"New_Obs_Shutter";
NSString *kAnalyticsEventNewObservationLibraryPicked =          @"New_Obs_Library_Picked";
NSString *kAnalyticsEventNewObservationNoPhoto =                @"New_Obs_No_Photo";
NSString *kAnalyticsEventNewObservationCancel =                 @"New_Obs_Cancel";
NSString *kAnalyticsEventNewObservationConfirmPhotos =          @"New_Obs_Confirm_Photos";
NSString *kAnalyticsEventNewObservationRetakePhotos =           @"New_Obs_Retake_Photos";
NSString *kAnalyticsEventNewObservationCategorizeTaxon =        @"New_Obs_Categorize_Taxon";
NSString *kAnalyticsEventNewObservationSkipCategorize =         @"New_Obs_Skip_Categorize";
NSString *kAnalyticsEventNewObservationSaveObservation =        @"New_Obs_Save_New_Observation";

// observation edits
NSString *kAnalyticsEventObservationCaptiveChanged =            @"Obs_Captive_Changed";
NSString *kAnalyticsEventObservationTaxonChanged =              @"Obs_Taxon_Changed";
NSString *kAnalyticsEventObservationProjectsChanged =           @"Obs_Projects_Changed";
NSString *kAnalyticsEventObservationGeoprivacyChanged =         @"Obs_Geoprivacy_Changed";
NSString *kAnalyticsEventObservationNotesChanged =              @"Obs_Notes_Changed";
NSString *kAnalyticsEventObservationDateChanged =               @"Obs_Date_Changed";
NSString *kAnalyticsEventObservationLocationChanged =           @"Obs_Location_Changed";
NSString *kAnalyticsEventObservationAddPhoto =                  @"Obs_Add_Photo";
NSString *kAnalyticsEventObservationDeletePhoto =               @"Obs_Delete_Photo";
NSString *kAnalyticsEventObservationNewDefaultPhoto =           @"Obs_New_Default_Photo";
NSString *kAnalyticsEventObservationViewHiresPhoto =            @"Obs_View_Hires_Photo";
NSString *kAnalyticsEventObservationDelete =                    @"Obs_Delete";
NSString *kAnalyticsEventObservationAddIdentification =         @"Obs_Add_Identification";

// view obs activities
NSString *kAnalyticsEventObservationShareStarted =              @"Obs_Share_Started";
NSString *kAnalyticsEventObservationShareCancelled =            @"Obs_Share_Cancelled";
NSString *kAnalyticsEventObservationShareFinished =             @"Obs_Share_Finished";
NSString *kAnalyticsEventObservationFave =                      @"Obs_Fave";
NSString *kAnalyticsEventObservationUnfave =                    @"Obs_Unfave";
NSString *kAnalyticsEventObservationPhotoFailedToLoad =         @"Obs_Photo_Failed_to_Load";

// settings
NSString *kAnalyticsEventSettingEnabled =                       @"Setting_Enabled";
NSString *kAnalyticsEventSettingDisabled =                      @"Setting_Disabled";
NSString *kAnalyticsEventSettingsNetworkChangeBegan =           @"Settings_Network_Change_Began";
NSString *kAnalyticsEventSettingsNetworkChangeCompleted =       @"Settings_Network_Change_Completed";
NSString *kAnalyticsEventProfilePhotoChanged =                  @"Profile_Photo_Changed";
NSString *kAnalyticsEventProfilePhotoRemoved =                  @"Profile_Photo_Removed";
NSString *kAnalyticsEventProfileLoginChanged =                  @"Profile_Username_Changed";
NSString *kAnalyticsEventSettingsRateUs =                       @"Settings_Rate_Us";
NSString *kAnalyticsEventSettingsDonate =                       @"Settings_Donate";
NSString *kAnalyticsEventSettingsOpenShop =                     @"Settings_Open_Shop";
NSString *kAnalyticsEventTutorial =                             @"Settings_Tutorial";

// news
NSString *kAnalyticsEventNewsOpenArticle =                      @"News_Open_Article";
NSString *kAnalyticsEventNewsTapLink =                          @"News_Tap_Link";
NSString *kAnalyticsEventNewsShareStarted =                     @"News_Share_Started";
NSString *kAnalyticsEventNewsShareCancelled =                   @"News_Share_Cancelled";
NSString *kAnalyticsEventNewsShareFinished =                    @"News_Share_Finished";

// guides
NSString *kAnalyticsEventDownloadGuideStarted =                 @"Guide_Download_Start";
NSString *kAnalyticsEventDownloadGuideCompleted =               @"Guide_Download_Complete";
NSString *kAnalyticsEventDeleteDownloadedGuide =                @"Guide_Download_Delete";

// background fetch
NSString *kAnalyticsEventBackgroundFetchFailed =                @"Background_Fetch_Failed";

// onboarding
NSString *kAnalyticsEventNavigateOnboardingScreenLogo =         @"Navigate_Onboarding_Logo";
NSString *kAnalyticsEventNavigateOnboardingScreenObserve =      @"Navigate_Onboarding_Observe";
NSString *kAnalyticsEventNavigateOnboardingScreenShare =        @"Navigate_Onboarding_Share";
NSString *kAnalyticsEventNavigateOnboardingScreenLearn =        @"Navigate_Onboarding_Learn";
NSString *kAnalyticsEventNavigateOnboardingScreenContribue =    @"Navigate_Onboarding_Contribute";
NSString *kAnalyticsEventNavigateOnboardingScreenLogin =        @"Navigate_Onboarding_Login";
NSString *kAnalyticsEventOnboardingLoginSkip =                  @"Onboarding_Login_Skip";
NSString *kAnalyticsEventOnboardingLoginCancel =                @"Onboarding_Login_Cancel";
NSString *kAnalyticsEventOnboardingLoginPressed =               @"Onboarding_Login_Action";

// permissions
NSString *kAnalyticsEventLocationPermissionsChanged =           @"Location_Permissions_Changed";
NSString *kAnalyticsEventCameraPermissionsChanged =             @"Camera_Permissions_Changed";
NSString *kAnalyticsEventPhotoLibraryPermissionsChanged =       @"Photo_Library_Permissions_Changed";

// suggestions
NSString *kAnalyticsEventLoadTaxaSearch =                       @"Load_Taxa_Search";
NSString *kAnalyticsEventSuggestionsLoaded =                    @"Suggestions_Loaded";
NSString *kAnalyticsEventSuggestionsFailed =                    @"Suggestions_Failed_to_Load";
NSString *kAnalyticsEventChoseTaxon =                           @"User_Chose_Taxon";
NSString *kAnalyticsEventShowTaxonDetails =                     @"User_Chose_Taxon_Details";
NSString *kAnalyticsEventSuggestionsImageGauge =                @"Suggestions_API_Call_Time_Image";
NSString *kAnalyticsEventSuggestionsObservationGauge =          @"Suggestions_API_Call_Time_Observation";

