import UIKit

/// List screen: browse and search recipes, filter by cuisine.
final class RecipeListViewController: UIViewController {

    private let store = DataStore.shared
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let cuisineControl: UISegmentedControl
    private let searchController = UISearchController(searchResultsController: nil)
    private let cellIdentifier = "RecipeCell"

    private let cuisineOptions: [String]
    private var filteredRecipes: [Recipe] = []
    private var searchText = ""

    init() {
        cuisineOptions = ["All"] + DataStore.shared.cuisines
        cuisineControl = UISegmentedControl(items: cuisineOptions)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Recipes"
        view.backgroundColor = .systemBackground
        setupSearch()
        setupLayout()
        applyFilter()
    }

    // MARK: Setup

    private func setupSearch() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search recipes"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    private func setupLayout() {
        cuisineControl.selectedSegmentIndex = 0
        cuisineControl.addTarget(self, action: #selector(cuisineChanged), for: .valueChanged)
        cuisineControl.translatesAutoresizingMaskIntoConstraints = false

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)

        view.addSubview(cuisineControl)
        view.addSubview(tableView)

        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            cuisineControl.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 8),
            cuisineControl.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
            cuisineControl.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16),

            tableView.topAnchor.constraint(equalTo: cuisineControl.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor)
        ])
    }

    // MARK: Filtering

    @objc private func cuisineChanged() {
        applyFilter()
    }

    private func applyFilter() {
        let selectedCuisine = cuisineControl.selectedSegmentIndex > 0
            ? cuisineOptions[cuisineControl.selectedSegmentIndex]
            : nil
        let query = searchText.trimmingCharacters(in: .whitespaces)

        filteredRecipes = store.recipes.filter { recipe in
            let matchesCuisine = selectedCuisine == nil || recipe.cuisine == selectedCuisine
            let matchesSearch = query.isEmpty
                || recipe.name.localizedCaseInsensitiveContains(query)
                || recipe.cuisine.localizedCaseInsensitiveContains(query)
            return matchesCuisine && matchesSearch
        }
        tableView.reloadData()
    }
}

// MARK: - UISearchResultsUpdating

extension RecipeListViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        searchText = searchController.searchBar.text ?? ""
        applyFilter()
    }
}

// MARK: - UITableViewDataSource

extension RecipeListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredRecipes.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        let recipe = filteredRecipes[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = recipe.name
        content.secondaryText = "\(recipe.cuisine) · \(recipe.prepMinutes) min · serves \(recipe.servings)"
        content.image = UIImage(systemName: recipe.symbolName)
        content.imageProperties.tintColor = .systemOrange
        content.imageProperties.reservedLayoutSize = CGSize(width: 44, height: 44)
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

// MARK: - UITableViewDelegate

extension RecipeListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let recipe = filteredRecipes[indexPath.row]
        navigationController?.pushViewController(RecipeDetailViewController(recipe: recipe), animated: true)
    }
}
