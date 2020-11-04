//
//  PickerViewController.swift
//  SharedAlbumExample
//
//  Created by Jeffrey Blagdon on 2020-11-04.
//

import UIKit
import Photos

class ThumbnailCell: UICollectionViewCell {
    let thumbnailImageView = UIImageView()
    let durationLabel = UILabel()
    var assetIdentifier: String?

    override init(frame: CGRect) {
        super.init(frame: frame)
        for subview in [thumbnailImageView, durationLabel] {
        contentView.addSubview(subview)
            subview.translatesAutoresizingMaskIntoConstraints = false
        }
        thumbnailImageView.contentMode = .scaleAspectFill
        thumbnailImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        thumbnailImageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        thumbnailImageView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        thumbnailImageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true

        durationLabel.textAlignment = .right
        durationLabel.textColor = .white
        durationLabel.font = UIFont.monospacedSystemFont(ofSize: 12, weight: .medium)
        contentView.trailingAnchor.constraint(equalToSystemSpacingAfter: durationLabel.trailingAnchor, multiplier: 1).isActive = true
        contentView.topAnchor.constraint(equalToSystemSpacingBelow: contentView.topAnchor, multiplier: 1).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        thumbnailImageView.image = nil
        assetIdentifier = nil
        durationLabel.text = nil
    }
}

extension PHPhotoLibrary {
    func thumbnailImage(for asset: PHAsset, size: CGSize, completion: @escaping (UIImage?) -> Void) -> PHImageRequestID {
        let imageRequestOptions = PHImageRequestOptions()
        imageRequestOptions.deliveryMode = .opportunistic
        imageRequestOptions.isNetworkAccessAllowed = true
        imageRequestOptions.isSynchronous = false
        return PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: imageRequestOptions) { image, _ in
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
}


class PickerViewController: UICollectionViewController {
    let photoLibrary: PHPhotoLibrary
    let collections: PHFetchResult<PHAssetCollection>
    weak var delegate: PickerViewControllerDelegate?

    static let itemSize: CGSize = CGSize(width: 100, height: 100)
    let layout: UICollectionViewFlowLayout = PickerViewController.newLayout()

    private static func newLayout() -> UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = PickerViewController.itemSize
        return layout
    }

    private lazy var durationFormatter: DateComponentsFormatter = {
        let fmtr = DateComponentsFormatter()
        fmtr.unitsStyle = .positional
        fmtr.allowedUnits = [.hour, .minute, .second]
        return fmtr
    }()

    init(photoLibrary: PHPhotoLibrary, collections: PHFetchResult<PHAssetCollection>) {
        self.photoLibrary = photoLibrary
        self.collections = collections
        super.init(collectionViewLayout: self.layout)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) not implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.register(ThumbnailCell.self, forCellWithReuseIdentifier: String(describing: ThumbnailCell.self))
    }

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return collections.count
    }

    var fetchResults: [String: PHFetchResult<PHAsset>] = [:]

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let collection = collections.object(at: section)
        if let result = fetchResults[collection.localIdentifier] {
            return result.count
        } else {
            let options = PHFetchOptions()
            options.includeAssetSourceTypes = .typeCloudShared
            let result = PHAsset.fetchAssets(in: collection, options: options)
            fetchResults[collection.localIdentifier] = result
            return result.count
        }
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let collection = collections.object(at: indexPath.section)
        let asset = fetchResults[collection.localIdentifier]!.object(at: indexPath.item)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: ThumbnailCell.self), for: indexPath) as! ThumbnailCell
        cell.assetIdentifier = asset.localIdentifier
        let components = DateComponents(second: Int(asset.duration))
        cell.durationLabel.text = durationFormatter.string(from: components)
        _ = photoLibrary.thumbnailImage(for: asset, size: PickerViewController.itemSize) { (image) in
            if cell.assetIdentifier == asset.localIdentifier {
                cell.thumbnailImageView.image = image
            }
        }

        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let collection = collections.object(at: indexPath.section)
        let assets = fetchResults[collection.localIdentifier]!
        delegate?.didSelect(asset: assets.object(at: indexPath.item))
    }
}

protocol PickerViewControllerDelegate: AnyObject {
    func didSelect(asset: PHAsset)
}
