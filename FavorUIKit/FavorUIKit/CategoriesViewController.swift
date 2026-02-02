//
//  CategoriesViewController.swift
//  FavorUIKit
//
//  Created by Jason Pepas on 2/1/26.
//


import UIKit
import Observation


protocol CategoriesViewControllerDelegate: AnyObject {
    func didSelect(category: BrowseJSON.CategoryJSON, from: CategoriesViewController)
}


// MARK: - CategoriesViewController

class CategoriesViewController: UIViewController {

    var client: FavorClient
    weak var delegate: CategoriesViewControllerDelegate? = nil

    var browseFetchState: FavorClient.FetchState<BrowseJSON> = .empty {
        didSet {
            _apply(browseFetchState: browseFetchState, oldValue: oldValue)
        }
    }

    init(client: FavorClient) {
        self.client = client
        super.init(nibName: nil, bundle: nil)
    }

    // MARK: Internals

    private let _tableView = UITableView()

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Cuisine"

        _tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(_tableView)
        view.addConstraints([
            _tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            _tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            _tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            _tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        _tableView.register(CategoryTableCell.self, forCellReuseIdentifier: CategoryTableCell.reuseIdentifier)
        _tableView.rowHeight = UITableView.automaticDimension
        _tableView.estimatedRowHeight = 100
        _tableView.delegate = self
        _tableView.dataSource = self

        _observationLoop()
        Task { @MainActor in
            await client.fetchBrowseIfNeeded()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    private func _apply(browseFetchState: FavorClient.FetchState<BrowseJSON>, oldValue: FavorClient.FetchState<BrowseJSON>?) {
        guard browseFetchState != oldValue else {
            return
        }
        _tableView.reloadData()
    }

    private func _observationLoop() {
        withObservationTracking { [weak self] in
            guard let self else { return }
            self.browseFetchState = client.browseFetchState
        } onChange: { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.browseFetchState = self.client.browseFetchState
                self._observationLoop()
            }
        }
    }
}


// MARK: - UITableViewDelegate, UITableViewDataSource

extension CategoriesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch browseFetchState {
        case .empty, .loading, .failed: return 0
        case .succeeded(let content, _):
            return content.categories.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CategoryTableCell.reuseIdentifier, for: indexPath) as! CategoryTableCell
        guard let category = browseFetchState.success?.categories.get(at: indexPath.row) else {
            return cell
        }
        cell.category = category
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let category = browseFetchState.success?.categories.get(at: indexPath.row) else {
            return
        }
        delegate?.didSelect(category: category, from: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}


// MARK: - CategoryTableCell

import Kingfisher

class CategoryTableCell: UITableViewCell {

    static let reuseIdentifier: String = "CategoryTableCell"

    var category: BrowseJSON.CategoryJSON? = nil {
        didSet {
            _apply(category: category)
        }
    }

    // MARK: Internals

    private var _imageView = UIImageView()
    private var _label = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        _imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(_imageView)
        contentView.addConstraints([
            _imageView.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor),
            _imageView.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            contentView.layoutMarginsGuide.bottomAnchor.constraint(greaterThanOrEqualTo: _imageView.bottomAnchor),
            _imageView.widthAnchor.constraint(equalToConstant: 80),
            _imageView.heightAnchor.constraint(equalToConstant: 80),
        ])
        _imageView.contentMode = .scaleAspectFill
        _imageView.layer.cornerRadius = 8
        _imageView.clipsToBounds = true

        _label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(_label)
        contentView.addConstraints([
            _label.leadingAnchor.constraint(equalToSystemSpacingAfter: _imageView.trailingAnchor, multiplier: 1),
            _label.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            _label.centerYAnchor.constraint(equalTo: _imageView.centerYAnchor),
        ])
        _label.font = UIFont.preferredFont(forTextStyle: .title2)
        _label.adjustsFontForContentSizeCategory = true
        _label.numberOfLines = 0
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func _apply(category: BrowseJSON.CategoryJSON?) {
        _label.text = category?.name
        _imageView.kf.setImage(with: category?.images.card_image)
    }
}


fileprivate extension FavorClient.FetchState<BrowseJSON> {
    var success: BrowseJSON? {
        if case .succeeded(let content, _) = self {
            return content
        } else {
            return nil
        }
    }
}
