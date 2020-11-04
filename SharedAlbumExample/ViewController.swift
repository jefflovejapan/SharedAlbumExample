//
//  ViewController.swift
//  SharedAlbumExample
//
//  Created by Jeffrey Blagdon on 2020-11-03.
//

import UIKit
import Photos

class ViewController: UIViewController, PickerViewControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad()
        spinner.hidesWhenStopped = true
        spinner.stopAnimating()
    }

    @IBOutlet var spinner: UIActivityIndicatorView!

    @IBAction func buttonTapped(_ sender: Any) {
        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumCloudShared, options: nil)
        let picker = PickerViewController.init(photoLibrary: PHPhotoLibrary.shared(), collections: collections)
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }

    func didSelect(asset: PHAsset) {
        dismiss(animated: true, completion: {
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .highQualityFormat
            options.version = .current
            self.spinner.startAnimating()
            PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { (maybeAsset, maybeMix, maybeInfo) in
                DispatchQueue.main.async {
                    self.update(with: maybeAsset)

                }
            }
        })
    }

    private func update(with maybeAsset: AVAsset?) {
        self.spinner.stopAnimating()
        let alert: UIAlertController
        if maybeAsset == nil {
            alert = UIAlertController(title: "Couldn't download asset!", message: nil, preferredStyle: .alert)
        } else {
            do {
                let reader = try AVAssetReader(asset: maybeAsset!)
                alert = UIAlertController(title: "Created a reader!", message: String(describing: reader), preferredStyle: .alert)
            } catch {
                alert = UIAlertController(title: "Error creating a reader!", message: String(describing: error), preferredStyle: .alert)
            }
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

