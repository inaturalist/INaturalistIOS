//
//  MediaPickerViewController.swift
//  iNaturalist
//
//  Created by Alex Shepard on 5/24/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

import UIKit
import FontAwesomeKit

@objc protocol MediaPickerDelegate {
    func choseMediaPickerItemAtIndex(_ idx: Int)
}

class MediaPickerViewController: UIViewController {
    @objc var showsNoPhotoOption = true
    @objc weak var mediaPickerDelegate: MediaPickerDelegate?

    var taxon: ExploreTaxonRealm?
    weak var collectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(MediaPickerCell.self, forCellWithReuseIdentifier: "MediaPickerCell")

        collectionView.backgroundColor = .white

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: self.view.topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor)
        ])

        self.collectionView = collectionView
    }
}

extension MediaPickerViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if showsNoPhotoOption {
            return 4
        } else {
            return 3
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {

        if showsNoPhotoOption {
            if indexPath.item == 0 {
                return noPhotoCellForItemAt(indexPath: indexPath)
            } else if indexPath.item == 1 {
                return cameraCellForItemAt(indexPath: indexPath)
            } else if indexPath.item == 2 {
                return photoLibraryCellForItemAt(indexPath: indexPath)
            } else {
                return recordSoundCellForItemAt(indexPath: indexPath)
            }
        } else {
            if indexPath.item == 0 {
                return cameraCellForItemAt(indexPath: indexPath)
            } else if indexPath.item == 1 {
                return photoLibraryCellForItemAt(indexPath: indexPath)
            } else {
                return recordSoundCellForItemAt(indexPath: indexPath)
            }
        }
    }

    func noPhotoCellForItemAt(indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "MediaPickerCell",
            for: indexPath
        ) as! MediaPickerCell   // swiftlint:disable:this force_cast
        cell.titleLabel.text = NSLocalizedString("No Photo", comment: "Title for No Photo button in media picker")

        if let composeIcon = FAKIonIcons.composeIcon(withSize: 50),
            let circleOutline = FAKIonIcons.iosCircleOutlineIcon(withSize: 80) {
            composeIcon.addAttribute(NSAttributedString.Key.foregroundColor.rawValue, value: UIColor.lightGray)
            circleOutline.addAttribute(NSAttributedString.Key.foregroundColor.rawValue, value: UIColor.lightGray)
            cell.iconImageView.image = UIImage(
                stackedIcons: [composeIcon, circleOutline],
                imageSize: CGSize(width: 100, height: 100)
            )
        }
        return cell
    }

    func cameraCellForItemAt(indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "MediaPickerCell",
            for: indexPath
        ) as! MediaPickerCell   // swiftlint:disable:this force_cast
        cell.titleLabel.text = NSLocalizedString("Camera", comment: "Title for Camera button in media picker")

        if let cameraIcon = FAKIonIcons.cameraIcon(withSize: 50),
            let circleOutline = FAKIonIcons.iosCircleOutlineIcon(withSize: 80) {
            cameraIcon.addAttribute(NSAttributedString.Key.foregroundColor.rawValue, value: UIColor.inatTint())
            circleOutline.addAttribute(NSAttributedString.Key.foregroundColor.rawValue, value: UIColor.inatTint())
            cell.iconImageView.image = UIImage(
                stackedIcons: [cameraIcon, circleOutline],
                imageSize: CGSize(width: 100, height: 100)
            )
        }
        return cell
    }

    func photoLibraryCellForItemAt(indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "MediaPickerCell",
            for: indexPath
        ) as! MediaPickerCell   // swiftlint:disable:this force_cast
        cell.titleLabel.text = NSLocalizedString(
            "Photo Library",
            comment: "Title for Photo Library button in media picker"
        )

        if let imagesIcon = FAKIonIcons.imagesIcon(withSize: 50),
            let circleOutline = FAKIonIcons.iosCircleOutlineIcon(withSize: 80) {
            imagesIcon.addAttribute(NSAttributedString.Key.foregroundColor.rawValue, value: UIColor.inatTint())
            circleOutline.addAttribute(NSAttributedString.Key.foregroundColor.rawValue, value: UIColor.inatTint())
            cell.iconImageView.image = UIImage(
                stackedIcons: [imagesIcon, circleOutline],
                imageSize: CGSize(width: 100, height: 100)
            )
        }
        return cell
    }

    func recordSoundCellForItemAt(indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "MediaPickerCell",
            for: indexPath
        ) as! MediaPickerCell   // swiftlint:disable:this force_cast
        cell.titleLabel.text = NSLocalizedString("Record Sound", comment: "Title for Camera button in media picker")

        if let micIcon = FAKIonIcons.micAIcon(withSize: 50),
            let circleOutline = FAKIonIcons.iosCircleOutlineIcon(withSize: 80) {
            micIcon.addAttribute(NSAttributedString.Key.foregroundColor.rawValue, value: UIColor.inatTint())
            circleOutline.addAttribute(NSAttributedString.Key.foregroundColor.rawValue, value: UIColor.inatTint())
            cell.iconImageView.image = UIImage(
                stackedIcons: [micIcon, circleOutline],
                imageSize: CGSize(width: 100, height: 100)
            )
        }
        return cell
    }
}

extension MediaPickerViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.mediaPickerDelegate?.choseMediaPickerItemAtIndex(indexPath.item)
    }
}

extension MediaPickerViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {

        return CGSize(width: 60, height: 150)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {

        return 1.0
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {

        return 1.0
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {

        let totalCellWidth = 60 * (showsNoPhotoOption ? 3 : 2)
        let totalSpacingWidth = 1 * ((showsNoPhotoOption ? 3 : 2) - 1)

        let leftInset = (collectionView.frame.size.width - CGFloat(totalCellWidth + totalSpacingWidth)) / 2
        let rightInset = leftInset
        print("left inset \(leftInset)")
        return UIEdgeInsets(top: 10, left: leftInset - 60, bottom: 0, right: rightInset - 60)
    }
}

class MediaPickerCell: UICollectionViewCell {
    weak var iconImageView: UIImageView!
    weak var titleLabel: UILabel!

    override init(frame: CGRect) {
        super.init(frame: frame)

        let iconImageView = UIImageView(frame: .zero)
        iconImageView.contentMode = .center
        let titleLabel = UILabel(frame: .zero)
        titleLabel.numberOfLines = 2
        titleLabel.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [iconImageView, titleLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.alignment = .center
        stack.distribution = .fillEqually
        stack.axis = .vertical
        stack.spacing = 0

        self.contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            stack.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor)
        ])

        self.titleLabel = titleLabel
        self.iconImageView = iconImageView
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        fatalError("Interface Builder is not supported!")
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        fatalError("Interface Builder is not supported!")
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        self.titleLabel.text = nil
        self.iconImageView.image = nil
    }
}
