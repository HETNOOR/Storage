//
//  ImageListViewController.swift
//  Storage
//
//  Created by Максим Герасимов on 29.11.2024.
//

import UIKit
import Combine
import SnapKit

class ImageListViewController: UIViewController {
    private var viewModel = ImageListViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.itemSize = CGSize(width: UIScreen.main.bounds.width / 2 - 15, height: UIScreen.main.bounds.width / 2 - 15)
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()
    
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private let addButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        viewModel.fetchImages()
        
        NotificationCenter.default.addObserver(self, selector: #selector(refreshImages), name: .didUploadImage, object: nil)
       
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        title = "Список изображений"
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(ImageCell.self, forCellWithReuseIdentifier: "ImageCell")
        
        addButton.setTitle("Добавить", for: .normal)
        addButton.backgroundColor = .lightGray
        addButton.layer.cornerRadius = 8
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        
        view.addSubview(collectionView)
        view.addSubview(activityIndicator)
        view.addSubview(addButton)
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview().inset(10)
            make.bottom.equalTo(addButton.snp.top).offset(-10)
        }
        
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        addButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-10)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }
    }
    
    private func setupBindings() {
        viewModel.$cellViewModels
                  .receive(on: DispatchQueue.main)
                  .sink { [weak self] _ in
                      self?.collectionView.reloadData()
                  }
                  .store(in: &cancellables)
            
        }

    
    @objc private func addButtonTapped() {
        let addImageVC = AddImageViewController()
        navigationController?.pushViewController(addImageVC, animated: true)
    }
    
    @objc private func refreshImages() {
        viewModel.fetchImages()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .didUploadImage, object: nil)
    }

}

// MARK: - UICollectionView Delegate & DataSource
extension ImageListViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.cellViewModels.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as? ImageCell else {
            return UICollectionViewCell()
        }
        
        let cellViewModel = viewModel.cellViewModels[indexPath.row]
        cell.configure(with: cellViewModel)
        cell.downloadAction = { [weak cellViewModel] in
            cellViewModel?.startDownload()
        }
        
        return cell
    }

}
