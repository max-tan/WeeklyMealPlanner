import UIKit

/// Home screen: the week at a glance (7 days x breakfast/lunch/dinner).
final class WeeklyPlanViewController: UIViewController {

    private let store = DataStore.shared
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let cellIdentifier = "MealCell"

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "This Week"
        view.backgroundColor = .systemGroupedBackground
        setupLayout()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    // MARK: Layout

    private func setupLayout() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)

        var addConfiguration = UIButton.Configuration.filled()
        addConfiguration.title = "Add Meal"
        addConfiguration.image = UIImage(systemName: "plus.circle.fill")
        addConfiguration.imagePadding = 6
        addConfiguration.baseBackgroundColor = .systemOrange
        let addButton = UIButton(configuration: addConfiguration, primaryAction: UIAction { [weak self] _ in
            self?.addMealTapped()
        })

        var shoppingConfiguration = UIButton.Configuration.tinted()
        shoppingConfiguration.title = "Shopping List"
        shoppingConfiguration.image = UIImage(systemName: "cart.fill")
        shoppingConfiguration.imagePadding = 6
        shoppingConfiguration.baseForegroundColor = .systemOrange
        shoppingConfiguration.baseBackgroundColor = .systemOrange
        let shoppingButton = UIButton(configuration: shoppingConfiguration, primaryAction: UIAction { [weak self] _ in
            self?.shoppingListTapped()
        })

        let buttonStack = UIStackView(arrangedSubviews: [addButton, shoppingButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(tableView)
        view.addSubview(buttonStack)

        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            buttonStack.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
            buttonStack.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16),
            buttonStack.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor, constant: -12),
            buttonStack.heightAnchor.constraint(equalToConstant: 48),

            tableView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: buttonStack.topAnchor, constant: -12)
        ])
    }

    // MARK: Actions

    private func addMealTapped() {
        navigationController?.pushViewController(AddMealViewController(), animated: true)
    }

    private func shoppingListTapped() {
        navigationController?.pushViewController(ShoppingListViewController(), animated: true)
    }
}

// MARK: - UITableViewDataSource

extension WeeklyPlanViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        Weekday.allCases.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        MealType.allCases.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        Weekday.allCases[section].title
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        let day = Weekday.allCases[indexPath.section]
        let mealType = MealType.allCases[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.image = UIImage(systemName: mealType.symbolName)
        content.imageProperties.tintColor = .systemOrange

        if let planned = store.plannedMeal(day: day, mealType: mealType),
           let recipe = store.recipe(withID: planned.recipeID) {
            content.text = recipe.name
            content.secondaryText = "\(mealType.title) · \(recipe.prepMinutes) min"
            cell.accessoryType = .disclosureIndicator
        } else {
            content.text = "Not planned"
            content.textProperties.color = .secondaryLabel
            content.secondaryText = mealType.title
            cell.accessoryType = .none
        }

        cell.contentConfiguration = content
        return cell
    }
}

// MARK: - UITableViewDelegate

extension WeeklyPlanViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let day = Weekday.allCases[indexPath.section]
        let mealType = MealType.allCases[indexPath.row]

        if let planned = store.plannedMeal(day: day, mealType: mealType),
           let recipe = store.recipe(withID: planned.recipeID) {
            navigationController?.pushViewController(RecipeDetailViewController(recipe: recipe), animated: true)
        } else {
            navigationController?.pushViewController(AddMealViewController(day: day, mealType: mealType), animated: true)
        }
    }
}
