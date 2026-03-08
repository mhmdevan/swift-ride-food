#if canImport(UIKit)
import UIKit

@MainActor
public final class OffersViewController: UIViewController, UICollectionViewDataSourcePrefetching, UICollectionViewDelegate {
    private static let badgeLabelTag = 401_501
    private static let representedIdentifierKey = "offers_represented_item_id"
    private static let fallbackImage = UIImage(systemName: "photo")

    private struct SectionIdentifier: Hashable {
        let id: UUID
        let title: String
        let style: OfferSectionStyle
    }

    private struct ItemIdentifier: Hashable {
        let id: UUID
        let title: String
        let subtitle: String
        let priceText: String
        let badgeText: String?
        let imageURL: URL?
    }

    private let viewModel: OffersViewModel
    private let imageLoader: any OfferImageLoading

    private var sectionIdentifiers: [SectionIdentifier] = []
    private var imageLoadTasksByItemID: [UUID: Task<Void, Never>] = [:]

    private lazy var collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
    private lazy var loadingIndicator = UIActivityIndicatorView(style: .large)
    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textAlignment = .center
        label.isHidden = true
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var retryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Retry", for: .normal)
        button.isHidden = true
        button.accessibilityIdentifier = "offers_retry_button"
        button.accessibilityHint = "Retries loading offers"
        button.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        return button
    }()
    private lazy var paginationLoadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.hidesWhenStopped = true
        indicator.accessibilityIdentifier = "offers_pagination_loading_indicator"
        indicator.accessibilityLabel = "Loading more offers"
        return indicator
    }()

    private lazy var paginationRetryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Retry loading more", for: .normal)
        button.isHidden = true
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = "offers_pagination_retry_button"
        button.accessibilityHint = "Retries pagination request"
        button.addTarget(self, action: #selector(retryPaginationTapped), for: .touchUpInside)
        return button
    }()

    private lazy var headerRegistration = UICollectionView.SupplementaryRegistration<TitleHeaderView>(
        elementKind: UICollectionView.elementKindSectionHeader
    ) { [weak self] headerView, _, indexPath in
        guard let self,
              indexPath.section < sectionIdentifiers.count else { return }

        headerView.configure(with: sectionIdentifiers[indexPath.section].title)
    }

    private lazy var dataSource = makeDataSource()

    public init(
        viewModel: OffersViewModel,
        imageLoader: any OfferImageLoading = DefaultOfferImageLoader()
    ) {
        self.viewModel = viewModel
        self.imageLoader = imageLoader
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        title = "Catalog"
        view.backgroundColor = .systemBackground

        setupViewHierarchy()
        setupConstraints()
        bindViewModel()
        collectionView.delegate = self
        collectionView.prefetchDataSource = self

        Task {
            await viewModel.loadOffers()
        }
    }

    @objc
    private func retryTapped() {
        Task {
            await viewModel.loadOffers()
        }
    }

    @objc
    private func retryPaginationTapped() {
        Task {
            await viewModel.retryLoadNextPage()
        }
    }

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }
        viewModel.onPaginationStateChange = { [weak self] state in
            self?.renderPagination(state)
        }
    }

    private func render(_ state: OffersViewState) {
        switch state {
        case .idle:
            loadingIndicator.stopAnimating()
            errorLabel.isHidden = true
            retryButton.isHidden = true
        case .loading:
            loadingIndicator.startAnimating()
            errorLabel.isHidden = true
            retryButton.isHidden = true
        case .loaded(let sections):
            loadingIndicator.stopAnimating()
            errorLabel.isHidden = true
            retryButton.isHidden = true
            applySnapshot(sections)
        case .empty(let message):
            loadingIndicator.stopAnimating()
            errorLabel.text = message
            errorLabel.isHidden = false
            retryButton.isHidden = true
            applySnapshot([])
        case .failed(let message):
            loadingIndicator.stopAnimating()
            errorLabel.text = message
            errorLabel.isHidden = false
            retryButton.isHidden = false
            applySnapshot([])
        }
    }

    private func renderPagination(_ state: OffersPaginationState) {
        switch state {
        case .idle, .exhausted:
            paginationLoadingIndicator.stopAnimating()
            paginationRetryButton.isHidden = true
        case .loading:
            paginationLoadingIndicator.startAnimating()
            paginationRetryButton.isHidden = true
        case .failed:
            paginationLoadingIndicator.stopAnimating()
            paginationRetryButton.isHidden = false
        }
    }

    private func applySnapshot(_ sections: [OfferSection]) {
        sectionIdentifiers = sections.map {
            SectionIdentifier(id: $0.id, title: $0.title, style: $0.style)
        }

        var snapshot = NSDiffableDataSourceSnapshot<SectionIdentifier, ItemIdentifier>()

        for section in sections {
            let sectionIdentifier = SectionIdentifier(id: section.id, title: section.title, style: section.style)
            snapshot.appendSections([sectionIdentifier])

            let items = section.items.map {
                ItemIdentifier(
                    id: $0.id,
                    title: $0.title,
                    subtitle: $0.subtitle,
                    priceText: $0.priceText,
                    badgeText: $0.badgeText,
                    imageURL: $0.imageURL
                )
            }
            snapshot.appendItems(items, toSection: sectionIdentifier)
        }

        dataSource.apply(snapshot, animatingDifferences: true)
        cleanupImageTasks(activeItems: Set(snapshot.itemIdentifiers.map(\.id)))
    }

    private func makeDataSource() -> UICollectionViewDiffableDataSource<SectionIdentifier, ItemIdentifier> {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewCell, ItemIdentifier> { [weak self] cell, _, item in
            guard let self else { return }

            cell.contentConfiguration = Self.makeContentConfiguration(for: item)
            cell.backgroundConfiguration = UIBackgroundConfiguration.listGroupedCell()
            cell.contentView.viewWithTag(Self.badgeLabelTag)?.removeFromSuperview()
            cell.accessibilityIdentifier = Self.representedIdentifierKey
            cell.accessibilityValue = item.id.uuidString
            cell.isAccessibilityElement = true
            cell.accessibilityLabel = "\(item.title), \(item.priceText)"
            cell.accessibilityHint = "Opens offer details"

            if let badgeText = item.badgeText {
                let badgeLabel = UILabel()
                badgeLabel.text = badgeText
                badgeLabel.font = .preferredFont(forTextStyle: .caption2)
                badgeLabel.adjustsFontForContentSizeCategory = true
                badgeLabel.textColor = .systemBlue
                badgeLabel.tag = Self.badgeLabelTag
                badgeLabel.translatesAutoresizingMaskIntoConstraints = false
                cell.contentView.addSubview(badgeLabel)
                NSLayoutConstraint.activate([
                    badgeLabel.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
                    badgeLabel.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -10)
                ])
            }

            cell.layer.cornerRadius = 12
            cell.layer.cornerCurve = .continuous
            cell.clipsToBounds = true

            guard let imageURL = item.imageURL else { return }
            imageLoadTasksByItemID[item.id]?.cancel()
            let task = Task<Void, Never> { [weak self, weak cell] in
                guard let self else { return }
                let image = await self.imageLoader.loadImage(from: imageURL)
                guard Task.isCancelled == false else { return }

                guard let cell,
                      cell.accessibilityIdentifier == Self.representedIdentifierKey,
                      cell.accessibilityValue == item.id.uuidString,
                      var content = cell.contentConfiguration as? UIListContentConfiguration else {
                    return
                }

                content.image = image ?? Self.fallbackImage
                cell.contentConfiguration = content
            }
            imageLoadTasksByItemID[item.id] = task
        }

        let source = UICollectionViewDiffableDataSource<SectionIdentifier, ItemIdentifier>(
            collectionView: collectionView
        ) { collectionView, indexPath, itemIdentifier in
            collectionView.dequeueConfiguredReusableCell(
                using: cellRegistration,
                for: indexPath,
                item: itemIdentifier
            )
        }

        source.supplementaryViewProvider = { [weak self] collectionView, _, indexPath in
            guard let self else { return nil }
            return collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }

        return source
    }

    private static func makeContentConfiguration(for item: ItemIdentifier) -> UIListContentConfiguration {
        var content = UIListContentConfiguration.subtitleCell()
        content.text = item.title
        content.secondaryText = "\(item.subtitle) · \(item.priceText)"
        content.textProperties.font = .preferredFont(forTextStyle: .headline)
        content.textProperties.adjustsFontForContentSizeCategory = true
        content.secondaryTextProperties.color = .secondaryLabel
        content.secondaryTextProperties.adjustsFontForContentSizeCategory = true
        content.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12)

        if item.imageURL != nil {
            content.image = fallbackImage
            content.imageProperties.maximumSize = CGSize(width: 52, height: 52)
            content.imageProperties.cornerRadius = 8
            content.imageToTextPadding = 12
        }

        return content
    }

    private func makeLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { [weak self] sectionIndex, _ in
            guard let self,
                  sectionIndex < sectionIdentifiers.count else {
                return nil
            }

            let sectionID = sectionIdentifiers[sectionIndex]
            switch sectionID.style {
            case .featuredCarousel:
                return Self.makeFeaturedSectionLayout()
            case .compactGrid:
                return Self.makeGridSectionLayout()
            }
        }
    }

    private static func makeFeaturedSectionLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .fractionalHeight(1.0)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.82),
            heightDimension: .absolute(164)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .groupPagingCentered
        section.interGroupSpacing = 12
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 16, bottom: 20, trailing: 16)
        section.boundarySupplementaryItems = [makeHeaderSupplementaryItem()]
        return section
    }

    private static func makeGridSectionLayout() -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(0.5),
            heightDimension: .absolute(110)
        )
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)

        let groupSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .estimated(220)
        )
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 2)

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 20, trailing: 10)
        section.boundarySupplementaryItems = [makeHeaderSupplementaryItem()]
        return section
    }

    private static func makeHeaderSupplementaryItem() -> NSCollectionLayoutBoundarySupplementaryItem {
        NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize: NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(34)
            ),
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment: .top
        )
    }

    private func setupViewHierarchy() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .systemBackground
        collectionView.accessibilityIdentifier = "offers_collection_view"
        collectionView.accessibilityLabel = "Offers collection"

        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.accessibilityIdentifier = "offers_loading_indicator"
        loadingIndicator.accessibilityLabel = "Offers loading"

        errorLabel.translatesAutoresizingMaskIntoConstraints = false
        errorLabel.accessibilityIdentifier = "offers_state_message"
        errorLabel.accessibilityLabel = "Offers state message"
        retryButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(collectionView)
        view.addSubview(loadingIndicator)
        view.addSubview(errorLabel)
        view.addSubview(retryButton)
        view.addSubview(paginationLoadingIndicator)
        view.addSubview(paginationRetryButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            errorLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -12),
            errorLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            errorLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),

            retryButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 12),
            retryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            paginationLoadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            paginationLoadingIndicator.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),

            paginationRetryButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            paginationRetryButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])
    }

    private func cleanupImageTasks(activeItems: Set<UUID>) {
        let obsoleteIDs = imageLoadTasksByItemID.keys.filter { activeItems.contains($0) == false }
        for id in obsoleteIDs {
            imageLoadTasksByItemID[id]?.cancel()
            imageLoadTasksByItemID[id] = nil
        }
    }

    public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let items = indexPaths.compactMap { dataSource.itemIdentifier(for: $0) }
        guard items.isEmpty == false else { return }

        for item in items {
            guard let imageURL = item.imageURL else { continue }
            imageLoader.prefetchImage(from: imageURL)
        }

        Task {
            await viewModel.loadNextPageIfNeeded(currentVisibleItemID: items.last?.id)
        }
    }

    public func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        let items = indexPaths.compactMap { dataSource.itemIdentifier(for: $0) }
        for item in items {
            guard let imageURL = item.imageURL else { continue }
            imageLoader.cancelPrefetch(for: imageURL)
        }
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplaying cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        imageLoadTasksByItemID[item.id]?.cancel()
        imageLoadTasksByItemID[item.id] = nil
    }
}

private final class TitleHeaderView: UICollectionReusableView {
    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .preferredFont(forTextStyle: .title3)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = .label
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            titleLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            titleLabel.topAnchor.constraint(equalTo: topAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with title: String) {
        titleLabel.text = title
    }
}
#endif
