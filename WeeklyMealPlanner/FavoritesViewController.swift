import UIKit

/// Saved favorite recipes. Tap for details, swipe right to plan, swipe left to remove.
final class FavoritesViewController: UIViewController {

    private let store = DataStore.shared
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()
    private let cellIdentifier = "FavoriteCell"
    private var favorites: [Recipe] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Favorites"
        view.backgroundColor = .systemBackground
        setupLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        favorites = store.favoriteRecipes
        tableView.reloadData()
        updateEmptyState()
    }

    // MARK: Layout

    private func setupLayout() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)

        emptyLabel.text = "No favorites yet.\nTap the heart on a recipe to save it here."
        emptyLabel.numberOfLines = 0
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = .secondaryLabel

        view.addSubview(tableView)
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor)
        ])
    }

    private func updateEmptyState() {
        tableView.backgroundView = favorites.isEmpty ? emptyLabel : nil
    }
}

// MARK: - UITableViewDataSource

extension FavoritesViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        favorites.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        let recipe = favorites[indexPath.row]

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

extension FavoritesViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let recipe = favorites[indexPath.row]
        navigationController?.pushViewController(RecipeDetailViewController(recipe: recipe), animated: true)
    }

    func tableView(_ tableView: UITableView,
                   leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let recipe = favorites[indexPath.row]
        let planAction = UIContextualAction(style: .normal, title: "Plan") { [weak self] _, _, completion in
            self?.navigationController?.pushViewController(AddMealViewController(recipe: recipe), animated: true)
            completion(true)
        }
        planAction.backgroundColor = .systemOrange
        planAction.image = UIImage(systemName: "calendar.badge.plus")
        return UISwipeActionsConfiguration(actions: [planAction])
    }

    func tableView(_ tableView: UITableView,
                   trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let removeAction = UIContextualAction(style: .destructive, title: "Remove") { [weak self] _, _, completion in
            guard let self = self else {
                completion(false)
                return
            }
            self.store.removeFavorite(self.favorites[indexPath.row].id)
            self.favorites = self.store.favoriteRecipes
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            self.updateEmptyState()
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [removeAction])
    }
}
