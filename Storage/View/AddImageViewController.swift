//
//  AddImageViewController.swift
//  Storage
//
//  Created by Максим Герасимов on 29.11.2024.
//

import UIKit
import SnapKit

class AddImageViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private let viewModel = AddImageViewModel()
    private let imageView = UIImageView()
    private let urlTextField = UITextField()
    private let uploadButton = UIButton(type: .system)
    private let galleryButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let previewLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        title = "Добавить изображение"
        
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .lightGray
        imageView.layer.cornerRadius = 8
        imageView.clipsToBounds = true
        
        urlTextField.placeholder = "Введите URL изображения"
        urlTextField.borderStyle = .roundedRect
        
        uploadButton.setTitle("Загрузить", for: .normal)
        uploadButton.backgroundColor = .systemBlue
        uploadButton.setTitleColor(.white, for: .normal)
        uploadButton.layer.cornerRadius = 8
        uploadButton.addTarget(self, action: #selector(uploadButtonTapped), for: .touchUpInside)
        
        galleryButton.setTitle("Галерея", for: .normal)
        galleryButton.backgroundColor = .systemGreen
        galleryButton.setTitleColor(.white, for: .normal)
        galleryButton.layer.cornerRadius = 8
        galleryButton.addTarget(self, action: #selector(galleryButtonTapped), for: .touchUpInside)
        
        previewLabel.text = "Превью (после обработки):"
        previewLabel.textAlignment = .center
        previewLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        previewLabel.isHidden = true
        
        view.addSubview(imageView)
        view.addSubview(previewLabel)
        view.addSubview(urlTextField)
        view.addSubview(uploadButton)
        view.addSubview(galleryButton)
        view.addSubview(activityIndicator)
        
        imageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(200)
        }
        
        previewLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview()
        }
        
        urlTextField.snp.makeConstraints { make in
            make.top.equalTo(previewLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        galleryButton.snp.makeConstraints { make in
            make.top.equalTo(urlTextField.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
            make.width.equalToSuperview().dividedBy(2).offset(-30)
            make.height.equalTo(50)
        }
        
        uploadButton.snp.makeConstraints { make in
            make.top.equalTo(urlTextField.snp.bottom).offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.width.equalToSuperview().dividedBy(2).offset(-30)
            make.height.equalTo(50)
        }
        
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private func bindViewModel() {
        viewModel.onImageProcessing = { [weak self] in
            DispatchQueue.main.async {
                self?.activityIndicator.startAnimating()
            }
        }
        
        viewModel.onImageProcessingFinished = { [weak self] success in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                if success {
                    self?.navigationController?.popViewController(animated: true)
                } else {
                    let alert = UIAlertController(title: "Ошибка", message: "Не удалось загрузить изображение", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(alert, animated: true)
                }
            }
        }
        
        viewModel.onPreviewUpdated = { [weak self] previewImage in
            DispatchQueue.main.async {
                self?.imageView.image = previewImage
                self?.previewLabel.isHidden = false
            }
        }
    }
    
    @objc private func galleryButtonTapped() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }
    
    @objc private func uploadButtonTapped() {
        if let selectedImage = viewModel.selectedImage {
            activityIndicator.startAnimating()
            viewModel.uploadImage(image: selectedImage)
            return
        }
        
        guard let urlText = urlTextField.text, !urlText.isEmpty else {
            showAlert(message: "Выберите изображение или введите URL.")
            return
        }
        
        guard viewModel.validateURL(urlText) else {
            showAlert(message: "Введите корректный URL.")
            return
        }
    
        activityIndicator.startAnimating()
        viewModel.loadImageFromURL(urlText) { [weak self] success in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                if success, let image = self?.viewModel.selectedImage {
                    self?.activityIndicator.startAnimating()
                    self?.viewModel.uploadImage(image: image)
                } else {
                    self?.showAlert(message: "Не удалось загрузить изображение с указанного URL.")
                }
            }
        }
    }

    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        dismiss(animated: true)
        if let image = info[.originalImage] as? UIImage {
            viewModel.preparePreviewImage(image)
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

