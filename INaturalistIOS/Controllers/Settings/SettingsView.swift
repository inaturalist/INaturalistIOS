//
//  SettingsView.swift
//  iNaturalist
//
//  Created by Alex Shepard on 9/30/22.
//  Copyright © 2022 iNaturalist. All rights reserved.
//

import SwiftUI

struct SettingsView: View {

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

                HStack {
                    Toggle("Autocomplete names", isOn: $viewModel.autocompleteNames)
                    Button {
                        print("tapped")
                    } label: {
                        Image(systemName: "info.circle")
                            .imageScale(.large)
                    }
                }

                HStack {
                    Toggle("Automatic upload", isOn: $viewModel.autoUpload)
                    Button {
                        print("tapped")
                    } label: {
                        Image(systemName: "info.circle")
                            .imageScale(.large)
                    }
                }

                HStack {
                    Toggle("Suggest species", isOn: $viewModel.suggestSpecies)
                    Button {
                        print("tapped")
                    } label: {
                        Image(systemName: "info.circle")
                            .imageScale(.large)
                    }
                }

                HStack {
                    Toggle("Show common names", isOn: $viewModel.showCommonNames)
                    Button {
                        print("tapped")
                    } label: {
                        Image(systemName: "info.circle")
                            .imageScale(.large)
                    }
                }

                HStack {
                    Toggle("Show scientific names first", isOn: $viewModel.showScientificNamesFirst)
                    Button {
                        print("tapped")
                    } label: {
                        Image(systemName: "info.circle")
                            .imageScale(.large)
                    }
                }

                HStack {
                    Toggle("Prefer No Tracking", isOn: $viewModel.preferNoTrack)
                    Button {
                        print("tapped")
                    } label: {
                        Image(systemName: "info.circle")
                            .imageScale(.large)
                    }
                }
            } header: {
                Text("App Settings")
            }

            Section {
                Button(
                    "Video Tutorial",
                    action: videoTutorial
                )
                Button(
                    "Contact support",
                    action: contactSupport
                )
                Button(
                    "Visit forums",
                    action: visitForums
                )
                Button(
                    "Love iNat? Rate us",
                    action: rate
                )
                Button(
                    "Shop the iNat Store",
                    action: shop
                )
                Button(
                    "Donate to iNaturalist",
                    action: donate
                )
            } header: {
                Text("Help")
            }

            Section {

            } header: {
                Text("Version")
            }

            Section {
                Button(
                    "Delete Account",
                    action: deleteAccount
                )
                .foregroundColor(.red)

            } header: {
                Text("Danger Zone")
            }
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
