import UIKit

/// Detail screen: one recipe with image, ingredients, instructions and actions.
final class RecipeDetailViewController: UIViewController {

    private let store = DataStore.shared
    private let recipe: Recipe

    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let favoriteButton = UIButton(type: .system)

    init(recipe: Recipe) {
        self.recipe = recipe
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = recipe.name
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemBackground
        setupLayout()
        updateFavoriteButton()
    }

    // MARK: Layout

    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.alignment = .fill

        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeArea.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safeArea.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -32)
        ])

        contentStack.addArrangedSubview(makeImageView())
        contentStack.addArrangedSubview(makeTitleLabel())
        contentStack.addArrangedSubview(makeInfoLabel())
        contentStack.addArrangedSubview(makeSectionLabel("Ingredients"))
        contentStack.addArrangedSubview(makeBodyLabel(
            recipe.ingredients.map { "• \($0.displayText)" }.joined(separator: "\n")))
        contentStack.addArrangedSubview(makeSectionLabel("Instructions"))
        contentStack.addArrangedSubview(makeBodyLabel(
            recipe.instructions.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n\n")))
        contentStack.addArrangedSubview(makeButtonStack())
    }

    private func makeImageView() -> UIImageView {
        let imageView = UIImageView(image: UIImage(systemName: recipe.symbolName))
        imageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 72)
        imageView.tintColor = .systemOrange
        imageView.contentMode = .center
        imageView.backgroundColor = .secondarySystemBackground
        imageView.layer.cornerRadius = 12
        imageView.clipsToBounds = true
        imageView.heightAnchor.constraint(equalToConstant: 160).isActive = true
        return imageView
    }

    private func makeTitleLabel() -> UILabel {
        let label = UILabel()
        label.text = recipe.name
        label.font = .preferredFont(forTextStyle: .title1)
        label.numberOfLines = 0
        return label
    }

    private func makeInfoLabel() -> UILabel {
        let label = UILabel()
        label.text = "\(recipe.cuisine) · \(recipe.prepMinutes) min · serves \(recipe.servings)"
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.textColor = .secondaryLabel
        return label
    }

    private func makeSectionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .headline)
        return label
    }

    private func makeBodyLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .body)
        label.numberOfLines = 0
        return label
    }

    private func makeButtonStack() -> UIStackView {
        var planConfiguration = UIButton.Configuration.filled()
        planConfiguration.title = "Add to Meal Plan"
        planConfiguration.image = UIImage(systemName: "calendar.badge.plus")
        planConfiguration.imagePadding = 6
        planConfiguration.baseBackgroundColor = .systemOrange
        let planButton = UIButton(configuration: planConfiguration, primaryAction: UIAction { [weak self] _ in
            guard let self = self else { return }
            self.navigationController?.pushViewController(AddMealViewController(recipe: self.recipe), animated: true)
        })

        favoriteButton.addAction(UIAction { [weak self] _ in
            guard let self = self else { return }
            self.store.toggleFavorite(self.recipe.id)
            self.updateFavoriteButton()
        }, for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [planButton, favoriteButton])
        stack.axis = .vertical
        stack.spacing = 10
        stack.distribution = .fillEqually
        planButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        return stack
    }

    private func updateFavoriteButton() {
        let isFavorite = store.isFavorite(recipe.id)
        var configuration = UIButton.Configuration.tinted()
        configuration.title = isFavorite ? "Remove from Favorites" : "Add to Favorites"
        configuration.image = UIImage(systemName: isFavorite ? "heart.fill" : "heart")
        configuration.imagePadding = 6
        configuration.baseForegroundColor = .systemRed
        configuration.baseBackgroundColor = .systemRed
        favoriteButton.configuration = configuration
    }
}
