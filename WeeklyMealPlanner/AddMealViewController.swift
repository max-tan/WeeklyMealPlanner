import UIKit

/// Add/Edit screen: choose a day, meal, and recipe to put in the weekly plan.
final class AddMealViewController: UIViewController {

    private let store = DataStore.shared

    private let daySegment = UISegmentedControl(items: Weekday.allCases.map { $0.shortTitle })
    private let mealSegment = UISegmentedControl(items: MealType.allCases.map { $0.title })
    private let recipePicker = UIPickerView()
    private let reminderSwitch = UISwitch()
    private let notesField = UITextField()
    private let formStack = UIStackView()

    private let initialDay: Weekday
    private let initialMealType: MealType
    private let initialRecipe: Recipe?

    init(day: Weekday? = nil, mealType: MealType? = nil, recipe: Recipe? = nil) {
        initialDay = day ?? Weekday.today
        initialMealType = mealType ?? .dinner
        initialRecipe = recipe
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Add Meal"
        navigationItem.largeTitleDisplayMode = .never
        view.backgroundColor = .systemBackground
        setupControls()
        setupLayout()

        let tap = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing(_:)))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    // MARK: Setup

    private func setupControls() {
        daySegment.selectedSegmentIndex = initialDay.rawValue
        mealSegment.selectedSegmentIndex = initialMealType.rawValue

        recipePicker.dataSource = self
        recipePicker.delegate = self
        if let recipe = initialRecipe,
           let row = store.recipes.firstIndex(where: { $0.id == recipe.id }) {
            recipePicker.selectRow(row, inComponent: 0, animated: false)
        }

        reminderSwitch.isOn = false
        reminderSwitch.onTintColor = .systemOrange

        notesField.placeholder = "Notes (optional)"
        notesField.borderStyle = .roundedRect
        notesField.returnKeyType = .done
        notesField.delegate = self
    }

    private func setupLayout() {
        let reminderLabel = UILabel()
        reminderLabel.text = "Remind me to prepare this meal"
        reminderLabel.font = .preferredFont(forTextStyle: .body)
        reminderLabel.numberOfLines = 0

        let reminderRow = UIStackView(arrangedSubviews: [reminderLabel, reminderSwitch])
        reminderRow.axis = .horizontal
        reminderRow.alignment = .center
        reminderRow.spacing = 12

        var saveConfiguration = UIButton.Configuration.filled()
        saveConfiguration.title = "Save Meal"
        saveConfiguration.baseBackgroundColor = .systemOrange
        let saveButton = UIButton(configuration: saveConfiguration, primaryAction: UIAction { [weak self] _ in
            self?.saveTapped()
        })
        saveButton.heightAnchor.constraint(equalToConstant: 48).isActive = true

        recipePicker.heightAnchor.constraint(equalToConstant: 130).isActive = true

        formStack.axis = .vertical
        formStack.spacing = 8
        formStack.translatesAutoresizingMaskIntoConstraints = false
        let formViews: [UIView] = [
            makeSectionLabel("Day"), daySegment,
            makeSectionLabel("Meal"), mealSegment,
            makeSectionLabel("Recipe"), recipePicker,
            reminderRow, notesField, saveButton
        ]
        formViews.forEach { formStack.addArrangedSubview($0) }

        formStack.setCustomSpacing(20, after: daySegment)
        formStack.setCustomSpacing(20, after: mealSegment)
        formStack.setCustomSpacing(16, after: recipePicker)
        formStack.setCustomSpacing(16, after: reminderRow)
        formStack.setCustomSpacing(24, after: notesField)

        view.addSubview(formStack)
        let safeArea = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            formStack.topAnchor.constraint(equalTo: safeArea.topAnchor, constant: 16),
            formStack.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 16),
            formStack.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: -16)
        ])
    }

    private func makeSectionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .headline)
        return label
    }

    // MARK: Actions

    private func saveTapped() {
        view.endEditing(true)
        let day = Weekday.allCases[daySegment.selectedSegmentIndex]
        let mealType = MealType.allCases[mealSegment.selectedSegmentIndex]
        let recipe = store.recipes[recipePicker.selectedRow(inComponent: 0)]

        store.setMeal(PlannedMeal(day: day,
                                  mealType: mealType,
                                  recipeID: recipe.id,
                                  wantsReminder: reminderSwitch.isOn,
                                  notes: notesField.text ?? ""))

        let alert = UIAlertController(title: "Meal Added",
                                      message: "\(recipe.name) was added to \(day.title) \(mealType.title.lowercased()).",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
}

// MARK: - UIPickerViewDataSource / Delegate

extension AddMealViewController: UIPickerViewDataSource, UIPickerViewDelegate {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        store.recipes.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        store.recipes[row].name
    }
}

// MARK: - UITextFieldDelegate

extension AddMealViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
