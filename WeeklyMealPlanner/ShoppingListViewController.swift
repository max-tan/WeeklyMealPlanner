import UIKit

/// Shopping list grouped by category, with check-off, custom items and Clear Completed.
final class ShoppingListViewController: UIViewController {

    private let store = DataStore.shared
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let summaryLabel = UILabel()
    private let emptyLabel = UILabel()
    private let cellIdentifier = "ShoppingCell"

    /// Categories that currently have items, with indices into `store.shoppingItems`.
    private var sections: [(category: IngredientCategory, indices: [Int])] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Shopping List"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemGroupedBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add,
                                                            target: self,
                                                            action: #selector(addItemTapped))
        setupLayout()
        reload()
    }

    // MARK: Layout

    private func setupLayout() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)

        emptyLabel.text = "Your shopping list is empty.\nPlan some meals or add a custom item."
        emptyLabel.numberOfLines = 0
        emptyLabel.textAlignment = .center
        emptyLabel.textColor = .secondaryLabel

        summaryLabel.font = .preferredFont(forTextStyle: .subheadline)
        summaryLabel.textColor = .secondaryLabel

        var clearConfiguration = UIButton.Configuration.filled()
        clearConfiguration.title = "Clear Completed"
        clearConfiguration.image = UIImage(systemName: "trash")
        clearConfiguration.imagePadding = 6
        clearConfiguration.baseBackgroundColor = .systemOrange
        let clearButton = UIButton(configuration: clearConfiguration, primaryAction: UIAction { [weak self] _ in
            self?.clearCompletedTapped()
        })
        clearButton.setContentHuggingPriority(.required, for: .horizontal)

        let bottomBar = UIStackView(arrangedSubviews: [summaryLabel, clearButton])
        bottomBar.axis = .horizontal
        bottomBar.alignment = .center
        bottomBar.spacing = 12
        bottomBar.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(tableView)
        view.addSubview(bottomBar)

        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            bottomBar.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
            bottomBar.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16),
            bottomBar.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -12),
            bottomBar.heightAnchor.constraint(equalToConstant: 48),

            tableView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor, constant: -12)
        ])
    }

    // MARK: Data

    private func reload() {
        let items = store.shoppingItems
        sections = IngredientCategory.allCases.compactMap { category -> (category: IngredientCategory, indices: [Int])? in
            let indices = items.indices.filter { items[$0].category == category }
            return indices.isEmpty ? nil : (category: category, indices: indices)
        }
        tableView.reloadData()
        tableView.backgroundView = items.isEmpty ? emptyLabel : nil

        let checkedCount = items.filter { $0.isChecked }.count
        summaryLabel.text = "\(checkedCount) of \(items.count) checked"
    }

    // MARK: Actions

    @objc private func addItemTapped() {
        let alert = UIAlertController(title: "Add Item", message: "Add something that isn't in a recipe.", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Item name" }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            let name = alert.textFields?.first?.text?.trimmingCharacters(in: .whitespaces) ?? ""
            guard !name.isEmpty else { return }
            self?.store.addCustomItem(name: name)
            self?.reload()
        })
        present(alert, animated: true)
    }

    private func clearCompletedTapped() {
        store.clearCompleted()
        reload()
    }
}

// MARK: - UITableViewDataSource

extension ShoppingListViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].indices.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].category.rawValue
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        let item = store.shoppingItems[sections[indexPath.section].indices[indexPath.row]]

        var content = cell.defaultContentConfiguration()
        content.image = UIImage(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
        content.imageProperties.tintColor = item.isChecked ? .systemGreen : .systemGray

        if item.isChecked {
            content.attributedText = NSAttributedString(string: item.name, attributes: [
                .strikethroughStyle: NSUnderlineStyle.single.rawValue,
                .foregroundColor: UIColor.secondaryLabel
            ])
        } else {
            content.text = item.name
        }
        content.secondaryText = item.detail.isEmpty ? nil : item.detail

        cell.contentConfiguration = content
        cell.accessoryType = .none
        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }
        store.deleteShoppingItem(at: sections[indexPath.section].indices[indexPath.row])
        reload()
    }
}

// MARK: - UITableViewDelegate

extension ShoppingListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        store.toggleChecked(at: sections[indexPath.section].indices[indexPath.row])
        reload()
    }
}
