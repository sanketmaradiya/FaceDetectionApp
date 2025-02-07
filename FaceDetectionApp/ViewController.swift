//
//  ViewController.swift
//  FaceDetectionApp
//
//  Created by Nimap on 06/02/25.
//

import UIKit

class ViewController: UIViewController, CameraViewControllerDelegate {

    var stackView: UIStackView?
    var imageView: UIImageView?
    var cameraButton: UIButton?
    var imageURL: URL? {
        didSet {
            if let url = imageURL {
                imageView?.image = UIImage(contentsOfFile: url.path)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        LoadUI()
    }

    func LoadUI() {
        view.backgroundColor = .white

        stackView = UIStackView()
        stackView!.axis = .vertical
        stackView!.alignment = .center
        stackView!.spacing = 20
        stackView!.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView!)

        NSLayoutConstraint.activate([
            stackView!.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView!.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView!.widthAnchor.constraint(
                equalTo: view.widthAnchor, multiplier: 0.9),
        ])

        imageView = UIImageView()
        imageView!.layer.cornerRadius = 10
        imageView!.contentMode = .scaleAspectFit
        imageView!.image = UIImage(systemName: "photo")
        imageView!.translatesAutoresizingMaskIntoConstraints = false
        stackView!.addArrangedSubview(imageView!)

        NSLayoutConstraint.activate([
            imageView!.widthAnchor.constraint(equalToConstant: 250),
            imageView!.heightAnchor.constraint(equalToConstant: 250),
        ])

        cameraButton = UIButton()
        cameraButton!.backgroundColor = .lightGray
        cameraButton!.translatesAutoresizingMaskIntoConstraints = false
        cameraButton!.setImage(UIImage(systemName: "camera"), for: .normal)
        cameraButton!.tintColor = .black
        cameraButton!.setTitleColor(.black, for: .normal)
        cameraButton!.layer.cornerRadius = 35
        cameraButton!.addTarget(
            self, action: #selector(OpenCamera), for: .touchUpInside)
        stackView!.addArrangedSubview(cameraButton!)
        NSLayoutConstraint.activate([
            cameraButton!.widthAnchor.constraint(equalToConstant: 70),
            cameraButton!.heightAnchor.constraint(equalToConstant: 70),
        ])
    }

    @objc func OpenCamera() {
        let cameraVC = CameraViewController()
        cameraVC.delegate = self
        navigationController?.pushViewController(cameraVC, animated: true)
    }

    func didCaptureImage(with url: URL) {
        self.imageURL = url
    }
}
