//
//  Analytics.h
//  iNaturalist
//
//  Created by Alex Shepard on 10/7/14.
//  Copyright (c) 2014 iNaturalist. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Analytics : NSObject

+ (Analytics *)sharedClient;

- (void)event:(NSString *)name;
- (void)event:(NSString *)name withProperties:(NSDictionary *)properties;
- (void)registerUserWithIdentifier:(NSString *)userIdentifier;

- (void)debugLog:(NSString *)logMessage;

- (void)logMetric:(NSString *)metricName value:(NSNumber *)metricValue;

@end

#pragma mark Event Names For Analytics

extern NSString *kAnalyticsEventAppLaunch;

extern NSString *kAnalyticsEventNavigateObservationDetail;

// search in explore
extern NSString *kAnalyticsEventExploreSearchPeople;
extern NSString *kAnalyticsEventExploreSearchProjects;
extern NSString *kAnalyticsEventExploreSearchPlaces;
extern NSString *kAnalyticsEventExploreSearchCritters;

extern NSString *kAnalyticsEventExploreSearchNearMe;
extern NSString *kAnalyticsEventExploreSearchMine;


// add comments & ids in explore
extern NSString *kAnalyticsEventExploreAddComment;
extern NSString *kAnalyticsEventExploreAddIdentification;

// observations activites
extern NSString *kAnalyticsEventCreateObservation;
extern NSString *kAnalyticsEventSyncObservation;
extern NSString *kAnalyticsEventSyncStopped;
extern NSString *kAnalyticsEventSyncFailed;

// login
extern NSString *kAnalyticsEventLogin;
extern NSString *kAnalyticsEventLoginFailed;
extern NSString *kAnalyticsEventSignup;
extern NSString *kAnalyticsEventLogout;
extern NSString *kAnalyticsEventForgotPassword;

// partners
extern NSString *kAnalyticsEventPartnerAlertPresented;
extern NSString *kAnalyticsEventPartnerAlertResponse;

// model integrity
extern NSString *kAnalyticsEventObservationlessOFVSaved;

// new observation flow
extern NSString *kAnalyticsEventNewObservationStart;
extern NSString *kAnalyticsEventNewObservationShutter;
extern NSString *kAnalyticsEventNewObservationLibraryStart;
extern NSString *kAnalyticsEventNewObservationLibraryPicked;
extern NSString *kAnalyticsEventNewObservationNoPhoto;
extern NSString *kAnalyticsEventNewObservationCancel;
extern NSString *kAnalyticsEventNewObservationConfirmPhotos;
extern NSString *kAnalyticsEventNewObservationRetakePhotos;
extern NSString *kAnalyticsEventNewObservationCategorizeTaxon;
extern NSString *kAnalyticsEventNewObservationSkipCategorize;
extern NSString *kAnalyticsEventNewObservationSaveObservation;

// observation edits
extern NSString *kAnalyticsEventObservationCaptiveChanged;
extern NSString *kAnalyticsEventObservationTaxonChanged;
extern NSString *kAnalyticsEventObservationIDPleaseChanged;
extern NSString *kAnalyticsEventObservationProjectsChanged;
extern NSString *kAnalyticsEventObservationGeoprivacyChanged;
extern NSString *kAnalyticsEventObservationNotesChanged;
extern NSString *kAnalyticsEventObservationDateChanged;
extern NSString *kAnalyticsEventObservationLocationChanged;
extern NSString *kAnalyticsEventObservationAddPhoto;
extern NSString *kAnalyticsEventObservationDeletePhoto;
extern NSString *kAnalyticsEventObservationNewDefaultPhoto;
extern NSString *kAnalyticsEventObservationViewHiresPhoto;
extern NSString *kAnalyticsEventObservationDelete;
extern NSString *kAnalyticsEventObservationAddIdentification;

// view obs activities
extern NSString *kAnalyticsEventObservationShareStarted;
extern NSString *kAnalyticsEventObservationShareCancelled;
extern NSString *kAnalyticsEventObservationShareFinished;
extern NSString *kAnalyticsEventObservationFave;
extern NSString *kAnalyticsEventObservationUnfave;
extern NSString *kAnalyticsEventObservationPhotoFailedToLoad;

// settings
extern NSString *kAnalyticsEventSettingEnabled;
extern NSString *kAnalyticsEventSettingDisabled;
extern NSString *kAnalyticsEventSettingsNetworkChangeBegan;
extern NSString *kAnalyticsEventSettingsNetworkChangeCompleted;
extern NSString *kAnalyticsEventProfilePhotoChanged;
extern NSString *kAnalyticsEventProfilePhotoRemoved;
extern NSString *kAnalyticsEventProfileLoginChanged;

// news
extern NSString *kAnalyticsEventNewsOpenArticle;
extern NSString *kAnalyticsEventNewsTapLink;
extern NSString *kAnalyticsEventNewsShareStarted;
extern NSString *kAnalyticsEventNewsShareCancelled;
extern NSString *kAnalyticsEventNewsShareFinished;

// guides
extern NSString *kAnalyticsEventDownloadGuideStarted;
extern NSString *kAnalyticsEventDownloadGuideCompleted;
extern NSString *kAnalyticsEventDeleteDownloadedGuide;

// background fetch
extern NSString *kAnalyticsEventBackgroundFetchFailed;

// onboarding
extern NSString *kAnalyticsEventNavigateOnboardingScreenLogo;
extern NSString *kAnalyticsEventNavigateOnboardingScreenObserve;
extern NSString *kAnalyticsEventNavigateOnboardingScreenShare;
extern NSString *kAnalyticsEventNavigateOnboardingScreenLearn;
extern NSString *kAnalyticsEventNavigateOnboardingScreenContribue;
extern NSString *kAnalyticsEventNavigateOnboardingScreenLogin;
extern NSString *kAnalyticsEventOnboardingLoginSkip;
extern NSString *kAnalyticsEventOnboardingLoginCancel;
extern NSString *kAnalyticsEventOnboardingLoginPressed;

// permissions
extern NSString *kAnalyticsEventLocationPermissionsChanged;
extern NSString *kAnalyticsEventCameraPermissionsChanged;
extern NSString *kAnalyticsEventPhotoLibraryPermissionsChanged;


// suggestions
extern NSString *kAnalyticsEventLoadTaxaSearch;
extern NSString *kAnalyticsEventSuggestionsLoaded;
extern NSString *kAnalyticsEventSuggestionsFailed;
extern NSString *kAnalyticsEventChoseTaxon;
extern NSString *kAnalyticsEventShowTaxonDetails;
extern NSString *kAnalyticsEventSuggestionsImageGauge;
extern NSString *kAnalyticsEventSuggestionsObservationGauge;

