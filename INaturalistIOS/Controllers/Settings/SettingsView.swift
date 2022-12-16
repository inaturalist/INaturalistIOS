//
//  SettingsView.swift
//  iNaturalist
//
//  Created by Alex Shepard on 9/30/22.
//  Copyright © 2022 iNaturalist. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    enum SettingsKeys: String {
        case userPrefAKey
    }

    @State private var userPrefA: Bool {
        didSet {
            UserDefaults.standard.set(userPrefA, forKey: SettingsKeys.userPrefAKey.rawValue)
        }
    }

    init() {
        userPrefA = UserDefaults.standard.bool(forKey: SettingsKeys.userPrefAKey.rawValue)
    }

    @ObservedObject var viewModel = ViewModel()

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Username")
                    Spacer()
                    Text("Blah")
                }

                HStack {
                    Text("Email address")
                    Spacer()
                    Text("blah@blah.com")
                }

                Button(
                    "Sign out",
                    action: { }
                )

            } header: {
                Text("Your Account")
            }

            Section {
                Button(
                    "Change username",
                    action: changeUsername
                )
                Button(
                    "Change email",
                    action: changeEmail
                )

                Toggle("User Pref A", isOn: $userPrefA)

//                HStack {
//                    Toggle("Autocomplete names", isOn: $viewModel.autocompleteNames)
//                    Button {
//                        print("tapped")
//                    } label: {
//                        Image(systemName: "info.circle")
//                            .imageScale(.large)
//                    }
//                }
//
//                HStack {
//                    Toggle("Automatic upload", isOn: $viewModel.autoUpload)
//                    Button {
//                        print("tapped")
//                    } label: {
//                        Image(systemName: "info.circle")
//                            .imageScale(.large)
//                    }
//                }
//
//                HStack {
//                    Toggle("Suggest species", isOn: $viewModel.suggestSpecies)
//                    Button {
//                        print("tapped")
//                    } label: {
//                        Image(systemName: "info.circle")
//                            .imageScale(.large)
//                    }
//                }
//
//                HStack {
//                    Toggle("Show common names", isOn: $viewModel.showCommonNames)
//                    Button {
//                        print("tapped")
//                    } label: {
//                        Image(systemName: "info.circle")
//                            .imageScale(.large)
//                    }
//                }
//
//                HStack {
//                    Toggle("Show scientific names first", isOn: $viewModel.showScientificNamesFirst)
//                    Button {
//                        print("tapped")
//                    } label: {
//                        Image(systemName: "info.circle")
//                            .imageScale(.large)
//                    }
//                }
//
//                HStack {
//                    Toggle("Prefer No Tracking", isOn: $viewModel.preferNoTrack)
//                    Button {
//                        print("tapped")
//                    } label: {
//                        Image(systemName: "info.circle")
//                            .imageScale(.large)
//                    }
//                }
            } header: {
                Text("App Settings")
            }

//            Section {
//                if let url = URL.tutorialURL {
//                    Link(
//                        "Video Tutorial",
//                        destination: url
//                    )
//                }
//
//                Button(
//                    "Contact support",
//                    action: contactSupport
//                )
//
//                if let url = URL.forumsURL {
//                    Link(
//                        "Visit forums",
//                        destination: url
//                    )
//                }
//
//                if let url = URL.rateURL {
//                    Link(
//                        "Love iNat? Rate us",
//                        destination: url
//                    )
//                }
//
//                if let url = URL.storeURL {
//                    Link(
//                        "Shop the iNat Store",
//                        destination: url
//                    )
//                }
//
//                if let url = URL.donateURL {
//                    Link(
//                        "Donate to iNaturalist",
//                        destination: url
//                    )
//                }
//
//            } header: {
//                Text("Help")
//            }
//
//            Section {
//                Text(viewModel.versionInfo)
//            } header: {
//                Text("Version")
//            }
//
//            Section {
//                Button(
//                    "Delete Account",
//                    action: deleteAccount
//                )
//                .foregroundColor(.red)
//
//            } header: {
//                Text("Danger Zone")
//            }
        }
        .navigationTitle("Settings")
        .toolbar {
            NavigationLink("About") {
                AboutView()
            }
        }
    }

    func changeUsername() {

    }

    func changeEmail() {

    }

    func videoTutorial() {

    }

    func contactSupport() {

    }

    func visitForums() {

    }

    func rate() {

    }

    func shop() {

    }

    func donate() {

    }

    func deleteAccount() {

    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}

/// So we can call from Objective-C
class SettingsViewFactory: NSObject {
    @objc static func makeSettingsView() -> UIViewController {
        return UIHostingController(rootView: SettingsView())
    }
}
