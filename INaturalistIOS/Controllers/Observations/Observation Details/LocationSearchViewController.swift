//
//  LocationSearchViewController.swift
//  iNaturalist
//
//  Created by Alex Shepard on 2/11/21.
//  Copyright © 2021 iNaturalist. All rights reserved.
//

import UIKit
import CoreLocation

@objc protocol LocationSearchDelegate {
    func locationSearchController(_ search: LocationSearchViewController, chosePlaceMark placemark: CLPlacemark)
    func locationSearchController(_ search: LocationSearchViewController, choseInatPlace location: ExploreLocation)
    func locationSearchControllerCancelled(_ search: LocationSearchViewController)
}

class LocationSearchViewController: UITableViewController {

    var cancelButton: UIBarButtonItem!
    var searchController: UISearchController!
    var placemarks = [CLPlacemark]()
    var inatPlaces = [ExploreLocation]()
    @objc weak var locationSearchDelegate: LocationSearchDelegate?

    let placeApi = PlaceAPI()

    override func viewDidLoad() {
        super.viewDidLoad()

        searchController = UISearchController(searchResultsController: nil)
        self.tableView.tableHeaderView = searchController.searchBar
        searchController.searchBar.showsSearchResultsButton = true
        searchController.searchBar.delegate = self

        self.tableView.tableFooterView = UIView()

        self.cancelButton = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelPressed)
        )
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        DispatchQueue.main.async {
            self.searchController.isActive = true
        }
    }

    @objc func cancelPressed() {
        self.locationSearchDelegate?.locationSearchControllerCancelled(self)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {

        if section == 0 {
            if self.placemarks.count > 0 {
                return NSLocalizedString(
                    "System Places",
                    comment: "Category of iOS standard places for place search"
                )
            } else {
                return nil
            }
        } else {
            if self.inatPlaces.count > 0 {
                return NSLocalizedString(
                    "iNaturalist Places",
                    comment: "Category of iNaturalist places for place search"
                )
            } else {
                return nil
            }
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return self.placemarks.count
        } else {
            return self.inatPlaces.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        var cell = tableView.dequeueReusableCell(withIdentifier: "placemark")
        if cell == nil {
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: "placemark")
        }

        if indexPath.section == 0 {
            let placemark = self.placemarks[indexPath.item]
            cell!.textLabel?.text = placemark.name
            cell!.textLabel?.numberOfLines = 0
            cell!.detailTextLabel?.text = placemark.inatPlaceGuess()
            cell!.detailTextLabel?.numberOfLines = 0
        } else {
            let place = self.inatPlaces[indexPath.item]
            cell!.textLabel?.text = place.name
            cell!.textLabel?.numberOfLines = 0
        }

        return cell!
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            self.locationSearchDelegate?.locationSearchController(
                self,
                chosePlaceMark: self.placemarks[indexPath.item]
            )
        } else {
            self.locationSearchDelegate?.locationSearchController(
                self,
                choseInatPlace: self.inatPlaces[indexPath.item]
            )
        }
     }
}

extension LocationSearchViewController: UISearchControllerDelegate {
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.locationSearchDelegate?.locationSearchControllerCancelled(self)
    }

    func didPresentSearchController(_ searchController: UISearchController) {
        searchController.searchBar.becomeFirstResponder()
    }
}

extension LocationSearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {

        self.inatPlaces = [ExploreLocation]()
        self.placemarks = [CLPlacemark]()

        DispatchQueue.main.async {
            self.searchController.isActive = false
            self.tableView.reloadData()
            self.view.endEditing(true)
        }

        var minCharsLocationSearch = 3
        let isHan = (searchBar.text?.range(of: "\\p{Han}", options: .regularExpression) != nil)
        if isHan {
            minCharsLocationSearch = 1
        }

        if let searchText = searchBar.text, searchText.count > minCharsLocationSearch {
            let geocoder = CLGeocoder()
            geocoder.geocodeAddressString(searchText) { (placemarks, error) in
                if let error = error {
                    print("error \(error.localizedDescription)")
                }
                if let marks = placemarks {
                    self.placemarks = marks
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.view.endEditing(true)
                }
            }

            // also search inat node api
            self.placeApi.places(matching: searchText) { (places, _, error) in
                if let error = error {
                    print("error \(error.localizedDescription)")
                }
                if let places = places as? [ExploreLocation] {
                    self.inatPlaces = places
                }

                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.view.endEditing(true)
                }
            }
        }
    }
}
