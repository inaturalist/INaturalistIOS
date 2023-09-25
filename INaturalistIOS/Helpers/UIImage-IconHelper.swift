//
//  UIImage-IconHelper.swift
//  iNaturalist
//
//  Created by Alex Shepard on 9/11/23.
//  Copyright © 2023 iNaturalist. All rights reserved.
//

import Foundation
import FontAwesomeKit


extension UIImage {
    @objc enum IconImageSize: Int {
        case xsmall, small, medium,  large, xlarge

        var iconSize: CGFloat {
            switch(self) {
            case .xsmall:
                return 10
            case .small:
                return 22
            case .medium:
                return 35
            case .large:
                return 50
            case .xlarge:
                return 75
            }
        }

        var imageSize: CGSize {
            switch(self) {
            case .xsmall:
                return CGSize(width: 10, height: 10)
            case .small:
                return CGSize(width: 25, height: 25)
            case .medium:
                return CGSize(width: 34, height: 45)
            case .large:
                return CGSize(width: 50, height: 50)
            case .xlarge:
                return CGSize(width: 75, height: 75)
            }
        }

        @available(iOS 13.0, *)
        var symbolConfig: UIImage.Configuration {
            switch(self) {
            case .xlarge, .large:
                return UIImage.SymbolConfiguration(pointSize: iconSize, weight: .regular, scale: .large)
            case .xsmall:
                return UIImage.SymbolConfiguration(pointSize: iconSize, weight: .regular, scale: .small)
            default:
                return UIImage.SymbolConfiguration(weight: .regular)
            }
        }

    }

    private static func fakImage(for systemName: String, size: IconImageSize) -> UIImage? {
        if systemName == "map" {
            return FAKIonIcons.mapIcon(withSize: size.iconSize).image(with: size.imageSize)
        } else if systemName == "list.dash" {
            return FAKIonIcons.naviconIcon(withSize: size.iconSize).image(with: size.imageSize)
        } else if systemName == "square.grid.3x3" {
            return FAKIonIcons.gridIcon(withSize: size.iconSize).image(with: size.imageSize)
        } else if systemName == "globe-random" {
            return FAKIonIcons.androidCompassIcon(withSize: size.iconSize).image(with: size.imageSize)
        } else if systemName == "camera.fill" {
            return FAKIonIcons.iosCameraIcon(withSize: size.iconSize).image(with: size.imageSize)
        } else if systemName == "bell.fill" {
            return FAKIonIcons.iosBellIcon(withSize: size.iconSize).image(with: size.imageSize)
        } else if systemName == "mic.circle" {
            return FAKIonIcons.micAIcon(withSize: size.iconSize).image(with: size.imageSize)
        } else if systemName == "pause.circle" {
            return FAKIonIcons.pauseIcon(withSize: size.iconSize).image(with: size.imageSize)
        } else if systemName == "speaker.wave.3.fill" {
            return FAKIonIcons.iosVolumeHighIcon(withSize: size.iconSize).image(with: size.imageSize)
        } else if systemName == "briefcase.fill" {
            return FAKIonIcons.iosBriefcaseIcon(withSize: size.iconSize).image(with: size.imageSize)
        } else if systemName == "briefcase" {
            return FAKIonIcons.iosBriefcaseOutlineIcon(withSize: size.iconSize).image(with: size.imageSize)
        } else if systemName == "square.and.pencil.circle" {
            return FAKIonIcons.composeIcon(withSize: size.iconSize).image(with: size.imageSize)
        } else if systemName == "photo.circle" {
            return FAKIonIcons.imagesIcon(withSize: size.iconSize).image(with: size.imageSize)
        } else if systemName == "camera.circle" {
            return FAKIonIcons.cameraIcon(withSize: size.iconSize).image(with: size.imageSize)
        } else if systemName == "mappin" {
            return FAKIonIcons.iosLocationOutlineIcon(withSize: size.iconSize).image(with: size.imageSize)
        } else if systemName == "chevron.backward.circle.fill" {
            return FAKIonIcons.iosArrowBackIcon(withSize: size.iconSize).image(with: size.imageSize)
        } else if systemName == "xmark" {
            return FAKIonIcons.closeIcon(withSize: size.iconSize).image(with: size.imageSize)
        } else if systemName == "xmark.circle.fill" {
            return FAKIonIcons.closeIcon(withSize: size.iconSize).image(with: size.imageSize)
        } else if systemName == "person" {
            return FAKIonIcons.personIcon(withSize: size.iconSize).image(with: size.imageSize)
        } else if systemName == "book" {
            return FAKIonIcons.iosBookOutlineIcon(withSize: size.iconSize).image(with: size.imageSize)
        } else if systemName == "plus" {
            return FAKIonIcons.iosPlusEmptyIcon(withSize: size.iconSize).image(with: size.imageSize)
        } else if systemName == "square.and.arrow.up.circle.fill" {
            return FAKIonIcons.iosUploadOutlineIcon(withSize: size.iconSize).image(with: size.imageSize)
        } else if systemName == "star" {
            return FAKIonIcons.iosStarOutlineIcon(withSize: size.iconSize).image(with: size.imageSize)
        } else if systemName == "star.fill" {
            return FAKIonIcons.iosStarIcon(withSize: size.iconSize).image(with: size.imageSize)
        }

        return nil
    }

    @objc static func iconImage(systemName: String, size: IconImageSize) -> UIImage? {
        if #available(iOS 16.0, *) {
            if systemName == "globe-random" {
                let globeChoices = [
                    "globe.central.south.asia.fill",
                    "globe.europe.africa.fill",
                    "globe.asia.australia.fill",
                    "globe.americas.fill",
                ]
                return UIImage(systemName: globeChoices.randomElement()!)
            }

            return UIImage(systemName: systemName, withConfiguration: size.symbolConfig)
        } else {
            return fakImage(for: systemName, size: size)
        }
    }
}
