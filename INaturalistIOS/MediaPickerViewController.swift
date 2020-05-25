//
//  MediaPickerViewController.swift
//  iNaturalist
//
//  Created by Alex Shepard on 5/24/20.
//  Copyright © 2020 iNaturalist. All rights reserved.
//

import UIKit
import FontAwesomeKit

protocol MediaPickerDelegate: NSObject {
    func choseItemAtIndex(_ idx: Int)
}

class MediaPickerViewController: UIViewController {
    var taxon: ExploreTaxonRealm?
    weak var mediaPickerDelegate: MediaPickerDelegate?
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
            collectionView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
        ])
        
        self.collectionView = collectionView
    }
}

extension MediaPickerViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 3
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MediaPickerCell", for: indexPath) as! MediaPickerCell
        
        if indexPath.item == 0 {
            cell.titleLabel.text = NSLocalizedString("No Photo", comment: "Title for No Photo button in media picker")
            
            if let composeIcon = FAKIonIcons.composeIcon(withSize: 50),
                let circleOutline = FAKIonIcons.iosCircleOutlineIcon(withSize: 80)
            {
                composeIcon.addAttribute(NSAttributedString.Key.foregroundColor.rawValue, value: UIColor.lightGray)
                circleOutline.addAttribute(NSAttributedString.Key.foregroundColor.rawValue, value: UIColor.lightGray)
                cell.iconImageView.image = UIImage(stackedIcons: [composeIcon, circleOutline], imageSize: CGSize(width: 100, height: 100))
            }
        } else if indexPath.item == 1 {
            cell.titleLabel.text = NSLocalizedString("Camera", comment: "Title for Camera button in media picker")
            
            if let cameraIcon = FAKIonIcons.cameraIcon(withSize: 50),
                let circleOutline = FAKIonIcons.iosCircleOutlineIcon(withSize: 80)
            {
                cameraIcon.addAttribute(NSAttributedString.Key.foregroundColor.rawValue, value: UIColor.inatTint())
                circleOutline.addAttribute(NSAttributedString.Key.foregroundColor.rawValue, value: UIColor.inatTint())
                cell.iconImageView.image = UIImage(stackedIcons: [cameraIcon, circleOutline], imageSize: CGSize(width: 100, height: 100))
            }
        } else if indexPath.item == 2 {
            cell.titleLabel.text = NSLocalizedString("Camera Roll", comment: "Title for Camera Roll button in media picker")
            
            if let imagesIcon = FAKIonIcons.imagesIcon(withSize: 50),
                let circleOutline = FAKIonIcons.iosCircleOutlineIcon(withSize: 80)
            {
                imagesIcon.addAttribute(NSAttributedString.Key.foregroundColor.rawValue, value: UIColor.inatTint())
                circleOutline.addAttribute(NSAttributedString.Key.foregroundColor.rawValue, value: UIColor.inatTint())
                cell.iconImageView.image = UIImage(stackedIcons: [imagesIcon, circleOutline], imageSize: CGSize(width: 100, height: 100))
            }
        }
        
        return cell
    }
}

extension MediaPickerViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.mediaPickerDelegate?.choseItemAtIndex(indexPath.item)
    }
}

extension MediaPickerViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 100, height: 100)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 1.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 25, bottom: 0, right: 25)
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
        
        let stack = UIStackView(arrangedSubviews: [iconImageView, titleLabel])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.alignment = .center
        stack.distribution = .fillProportionally
        stack.axis = .vertical
        
        self.contentView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: self.contentView.topAnchor),
            stack.bottomAnchor.constraint(equalTo: self.contentView.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor),
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

