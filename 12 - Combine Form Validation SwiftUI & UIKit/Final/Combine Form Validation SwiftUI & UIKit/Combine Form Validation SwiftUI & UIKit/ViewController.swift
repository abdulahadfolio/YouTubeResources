//
//  ViewController.swift
//  Combine Form Validation SwiftUI & UIKit
//
//  Created by Tunde on 03/05/2021.
//

import UIKit
import Combine

class ViewController: UIViewController {
    
    private lazy var formContentBuilder = FormContentBuilderImpl()
    private lazy var formCompositionalLayout = FormCompositionalLayout()
    private lazy var dataSource = makeDataSource()
    
    private lazy var collectionVw: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: formCompositionalLayout.layout)
        cv.backgroundColor = .clear
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.register(UICollectionViewCell.self, forCellWithReuseIdentifier: UICollectionViewCell.cellId)
        cv.register(FormButtonCollectionViewCell.self, forCellWithReuseIdentifier: FormButtonCollectionViewCell.cellId)
        cv.register(FormTextCollectionViewCell.self, forCellWithReuseIdentifier: FormTextCollectionViewCell.cellId)
        cv.register(FormDateCollectionViewCell.self, forCellWithReuseIdentifier: FormDateCollectionViewCell.cellId)
        return cv
    }()
    
    private var subscriptions = Set<AnyCancellable>()
    
    override func loadView() {
        super.loadView()
        setup()
        updateDataSource()
    }
}

private extension ViewController {
    
    func updateDataSource(animated: Bool = false) {
        
        DispatchQueue.main.async { [weak self] in
            
            guard let self = self else { return }
            
            var snapshot = NSDiffableDataSourceSnapshot<FormSectionComponent, FormComponent>()
            
            let formSections = self.formContentBuilder.formContent
            snapshot.appendSections(formSections)
            formSections.forEach { snapshot.appendItems($0.items, toSection: $0) }
            
            self.dataSource.apply(snapshot, animatingDifferences: animated)
        }
    }
    
    func makeDataSource() -> UICollectionViewDiffableDataSource<FormSectionComponent, FormComponent> {
        
        return UICollectionViewDiffableDataSource(collectionView: collectionVw) { collectionVw, indexPath, item in
            
            switch item {
            case is TextFormComponent:
                let cell = collectionVw.dequeueReusableCell(withReuseIdentifier: FormTextCollectionViewCell.cellId,
                                                            for: indexPath) as! FormTextCollectionViewCell
                cell
                    .subject
                    .sink { [weak self] (val, indexPath) in
                        self?.formContentBuilder.update(val: val, at: indexPath)
                    }.store(in: &self.subscriptions)
                
                cell.bind(item, at: indexPath)
                return cell
            case is DateFormComponent:
                let cell = collectionVw.dequeueReusableCell(withReuseIdentifier: FormDateCollectionViewCell.cellId,
                                                            for: indexPath) as! FormDateCollectionViewCell
                
                cell
                    .subject
                    .sink { [weak self] (val, indexPath) in
                        self?.formContentBuilder.update(val: val, at: indexPath)
                    }.store(in: &self.subscriptions)
                
                cell.bind(item, at: indexPath)
                return cell
            case is ButtonFormItem:
                let cell = collectionVw.dequeueReusableCell(withReuseIdentifier: FormButtonCollectionViewCell.cellId,
                                                            for: indexPath) as! FormButtonCollectionViewCell
                cell
                    .subject
                    .sink { [weak self] id in
                        self?.formContentBuilder.validate()
                    }.store(in: &self.subscriptions)
                cell.bind(item)
                return cell
            default:
                let cell = collectionVw.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
                return cell
            }
        }
    }
}

private extension ViewController {
    
    func setup() {
        
        // Observe the combine passthrough subject here for new data when the button is tapped
        newUserSubscription()
        
        view.backgroundColor = .white
        
        // Setup CollectionView
        
        collectionVw.dataSource = dataSource
        
        // Layout
        
        view.addSubview(collectionVw)
        
        NSLayoutConstraint.activate([
            collectionVw.topAnchor.constraint(equalTo: view.topAnchor),
            collectionVw.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            collectionVw.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionVw.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }
    
    func newUserSubscription() {
        
        formContentBuilder
            .user
            .sink { val in
            print(val)
        }
        .store(in: &subscriptions)
    }
}
