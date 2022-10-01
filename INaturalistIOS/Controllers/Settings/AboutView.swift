//
//  AboutView.swift
//  iNaturalist
//
//  Created by Alex Shepard on 9/30/22.
//  Copyright © 2022 iNaturalist. All rights reserved.
//

import SwiftUI
import AcknowList

struct AboutView: View {
    let acknowList: [Acknow]!
    var viewModel = ViewModel()

    init() {
        UITableView.appearance().separatorStyle = .none
        UITableView.appearance().separatorColor = UIColor.white

        guard let plistUrl = Bundle.main.url(
            forResource: "Pods-iNaturalist-acknowledgements",
            withExtension: "plist"
        ),
              let data = try? Data(contentsOf: plistUrl),
              let acknowList = try? AcknowPodDecoder().decode(from: data) else {

            fatalError("Could not find or decode plist for acknowledgements.")
        }

        self.acknowList = acknowList.acknowledgements

    }

    var body: some View {
        List {
            Section {
                // swiftlint:disable:next line_length
                Text("iNaturalist is a joint initiative of the California Academy of Sciences and the National Geographic Society")
                Text("https://www.inaturalist.org")
                Image("cas-ngs-logos")
            }

            Section {
                ForEach(viewModel.coreCredits, id: \.self) { acknowledgment in
                    Text(acknowledgment)
                        .font(.footnote)
                }
            } header: {
                Text("Credits")
            }

            Section {
                ForEach(viewModel.network, id: \.self) { networkAcknowledgement in
                    Text(networkAcknowledgement)
                        .font(.footnote)
                }
            } header: {
                Text("iNaturalist Network")
            }

            Section {
                ForEach(viewModel.otherAcknowledgements, id: \.self) { acknowledgment in
                    Text(acknowledgment)
                        .font(.footnote)
                }
            } header: {
                Text("Other acknowledgements")
            }

            Section {
                ForEach(acknowList) { acknowledgement in
                    NavigationLink(destination: AcknowSwiftUIView(acknowledgement: acknowledgement)) {
                        Text(acknowledgement.title)
                    }
                }
            } header: {
                Text("Open Source")
            }
        }
        .navigationTitle("About")
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
