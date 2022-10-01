//
//  SettingsViewModel.swift
//  iNaturalist
//
//  Created by Alex Shepard on 9/30/22.
//  Copyright © 2022 iNaturalist. All rights reserved.
//

import Foundation
import SwiftUI

extension SettingsView {
    class ViewModel: ObservableObject {
        @Published var autocompleteNames: Bool {
            didSet {
                UserDefaults.standard.set(autocompleteNames, forKey: kINatAutocompleteNamesPrefKey)
            }
        }

        @Published var autoUpload = false {
            didSet {
                UserDefaults.standard.set(autoUpload, forKey: kInatAutouploadPrefKey)
            }
        }

        @Published var suggestSpecies: Bool {
            didSet {
                UserDefaults.standard.set(suggestSpecies, forKey: kINatSuggestionsPrefKey)
            }
        }

        @Published var showCommonNames: Bool {
            didSet {
                UserDefaults.standard.set(showCommonNames, forKey: kINatShowCommonNamesPrefKey)
            }
        }

        @Published var showScientificNamesFirst: Bool {
            didSet {
                UserDefaults.standard.set(showScientificNamesFirst, forKey: kINatShowScientificNamesFirstPrefKey)
            }
        }

        @Published var preferNoTrack = false {
            didSet {
                UserDefaults.standard.set(preferNoTrack, forKey: kINatPreferNoTrackPrefKey)
            }
        }

        init() {
            // autocomplete names defaults to true
            self.autocompleteNames = UserDefaults.standard.object(
                forKey: kINatAutocompleteNamesPrefKey
            ) as? Bool ?? true

            // autoupload defaults to true
            self.autoUpload = UserDefaults.standard.object(
                forKey: kInatAutouploadPrefKey
            ) as? Bool ?? true

            // suggestions defaults to true
            self.suggestSpecies = UserDefaults.standard.object(
                forKey: kINatSuggestionsPrefKey
            ) as? Bool ?? true

            // show common names first defaults to true
            self.showCommonNames = UserDefaults.standard.object(
                forKey: kINatShowCommonNamesPrefKey
            ) as? Bool ?? true

            // show scientific names first defaults to false
            self.showScientificNamesFirst = UserDefaults.standard.object(
                forKey: kINatShowScientificNamesFirstPrefKey
            ) as? Bool ?? false

            // prefers no track defaults to false
            self.preferNoTrack = UserDefaults.standard.object(
                forKey: kINatPreferNoTrackPrefKey
            ) as? Bool ?? false
        }
    }
}
