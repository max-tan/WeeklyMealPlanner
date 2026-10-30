import UIKit

// MARK: - Enums

enum MealType: Int, CaseIterable {
    case breakfast, lunch, dinner

    var title: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        }
    }

    var symbolName: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        }
    }
}

enum Weekday: Int, CaseIterable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday

    var title: String {
        switch self {
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        case .sunday: return "Sunday"
        }
    }

    var shortTitle: String { String(title.prefix(3)) }

    /// Index of today in a Monday-first week.
    static var today: Weekday {
        let calendarWeekday = Calendar.current.component(.weekday, from: Date()) // 1 = Sunday
        return Weekday(rawValue: (calendarWeekday + 5) % 7) ?? .monday
    }
}

enum IngredientCategory: String, CaseIterable {
    case produce = "Produce"
    case dairy = "Dairy"
    case proteins = "Proteins"
    case pantry = "Pantry"
    case other = "Other"
}

// MARK: - Structs

struct Ingredient {
    let name: String
    let amount: Double
    let unit: String
    let category: IngredientCategory

    static func format(_ amount: Double) -> String {
        if amount.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(amount))
        }
        return String(amount)
    }

    var displayText: String {
        let amountText = Ingredient.format(amount)
        return unit.isEmpty ? "\(amountText) \(name)" : "\(amountText) \(unit) \(name)"
    }
}

struct Recipe {
    let id: Int
    let name: String
    let cuisine: String
    let prepMinutes: Int
    let servings: Int
    let symbolName: String
    let ingredients: [Ingredient]
    let instructions: [String]
}

struct PlannedMeal {
    let day: Weekday
    let mealType: MealType
    let recipeID: Int
    var wantsReminder: Bool
    var notes: String
}

struct ShoppingItem {
    var name: String
    var detail: String
    var category: IngredientCategory
    var isChecked: Bool
    var isCustom: Bool
}
