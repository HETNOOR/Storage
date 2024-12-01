//
//  ImageCell.swift
//  Storage
//
//  Created by Максим Герасимов on 29.11.2024.
//

import UIKit
import Combine
import SnapKit

class ImageCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let progressView = UIProgressView(progressViewStyle: .default)
    private let progressLabel = UILabel()
    private let downloadButton = UIButton(type: .system)
    private var cancellables = Set<AnyCancellable>()
    var downloadAction: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(imageView)
        contentView.addSubview(progressView)
        contentView.addSubview(progressLabel)
        contentView.addSubview(downloadButton)
        
        imageView.contentMode = .scaleAspectFit
        imageView.isHidden = true
        
        progressLabel.textAlignment = .center
        progressLabel.isHidden = true
        
        progressView.isHidden = true
        
        downloadButton.setTitle("Скачать", for: .normal)
        downloadButton.addTarget(self, action: #selector(downloadTapped), for: .touchUpInside)
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        progressView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(10)
            make.bottom.equalToSuperview().inset(20)
        }
        
        progressLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(progressView.snp.centerY)
        }
        
        downloadButton.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    func configure(with viewModel: ImageCellViewModel) {
        cancellables.forEach { $0.cancel() } // Отменяем предыдущие подписки
        cancellables.removeAll() // Очищаем список подписок
        
        viewModel.$downloadedImage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] image in
                self?.imageView.image = image
                self?.imageView.isHidden = (image == nil)
                self?.downloadButton.isHidden = (image != nil)
            }
            .store(in: &cancellables)
        
        viewModel.$progress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.progressView.progress = progress
                self?.progressLabel.text = "\(Int(progress * 100))%"
                self?.progressView.isHidden = (progress == 0 || progress == 1)
                self?.progressLabel.isHidden = (progress == 0 || progress == 1)
            }
            .store(in: &cancellables)
        
        viewModel.$isDownloading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDownloading in
                self?.downloadButton.isHidden = isDownloading
            }
            .store(in: &cancellables)
    }

    
    @objc private func downloadTapped() {
        downloadAction?()
    }
}
