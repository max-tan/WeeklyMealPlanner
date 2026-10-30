import Foundation

/// In-memory store with hard-coded sample data (Milestone 1: no persistence yet).
final class DataStore {

    static let shared = DataStore()

    let recipes: [Recipe]
    private(set) var plan: [PlannedMeal]
    private(set) var favoriteIDs: [Int]
    private(set) var shoppingItems: [ShoppingItem] = []

    var cuisines: [String] {
        var seen: [String] = []
        for recipe in recipes where !seen.contains(recipe.cuisine) {
            seen.append(recipe.cuisine)
        }
        return seen
    }

    private init() {
        recipes = DataStore.makeSampleRecipes()
        plan = [
            PlannedMeal(day: .monday, mealType: .breakfast, recipeID: 2, wantsReminder: false, notes: ""),
            PlannedMeal(day: .monday, mealType: .dinner, recipeID: 4, wantsReminder: true, notes: ""),
            PlannedMeal(day: .tuesday, mealType: .breakfast, recipeID: 1, wantsReminder: false, notes: ""),
            PlannedMeal(day: .tuesday, mealType: .lunch, recipeID: 3, wantsReminder: false, notes: ""),
            PlannedMeal(day: .tuesday, mealType: .dinner, recipeID: 6, wantsReminder: true, notes: ""),
            PlannedMeal(day: .wednesday, mealType: .dinner, recipeID: 5, wantsReminder: false, notes: ""),
            PlannedMeal(day: .thursday, mealType: .breakfast, recipeID: 8, wantsReminder: false, notes: ""),
            PlannedMeal(day: .friday, mealType: .dinner, recipeID: 7, wantsReminder: false, notes: "")
        ]
        favoriteIDs = [4, 5]
        regenerateShoppingList()
        // Pre-check one item so the checked style is visible in screenshots.
        if let index = shoppingItems.firstIndex(where: { $0.name == "Rolled oats" }) {
            shoppingItems[index].isChecked = true
        }
    }

    // MARK: Recipes

    func recipe(withID id: Int) -> Recipe? {
        recipes.first { $0.id == id }
    }

    // MARK: Meal plan

    func plannedMeal(day: Weekday, mealType: MealType) -> PlannedMeal? {
        plan.first { $0.day == day && $0.mealType == mealType }
    }

    /// Adds a meal, replacing whatever was in that day/meal slot.
    func setMeal(_ meal: PlannedMeal) {
        plan.removeAll { $0.day == meal.day && $0.mealType == meal.mealType }
        plan.append(meal)
        regenerateShoppingList()
    }

    // MARK: Favorites

    func isFavorite(_ recipeID: Int) -> Bool {
        favoriteIDs.contains(recipeID)
    }

    func toggleFavorite(_ recipeID: Int) {
        if let index = favoriteIDs.firstIndex(of: recipeID) {
            favoriteIDs.remove(at: index)
        } else {
            favoriteIDs.append(recipeID)
        }
    }

    func removeFavorite(_ recipeID: Int) {
        favoriteIDs.removeAll { $0 == recipeID }
    }

    var favoriteRecipes: [Recipe] {
        favoriteIDs.compactMap { recipe(withID: $0) }
    }

    // MARK: Shopping list

    /// Rebuilds the generated part of the list from the meal plan, merging duplicate
    /// ingredients. Custom items and checked state are preserved.
    func regenerateShoppingList() {
        var totals: [String: (amount: Double, unit: String, category: IngredientCategory, name: String)] = [:]
        var order: [String] = []

        for meal in plan {
            guard let recipe = recipe(withID: meal.recipeID) else { continue }
            for ingredient in recipe.ingredients {
                let key = ingredient.name.lowercased() + "|" + ingredient.unit
                if var existing = totals[key] {
                    existing.amount += ingredient.amount
                    totals[key] = existing
                } else {
                    totals[key] = (ingredient.amount, ingredient.unit, ingredient.category, ingredient.name)
                    order.append(key)
                }
            }
        }

        let previouslyChecked = Set(shoppingItems.filter { $0.isChecked && !$0.isCustom }.map { $0.name })
        let custom = shoppingItems.filter { $0.isCustom }

        let generated: [ShoppingItem] = order.compactMap { key in
            guard let total = totals[key] else { return nil }
            let amountText = Ingredient.format(total.amount)
            let detail = total.unit.isEmpty ? amountText : "\(amountText) \(total.unit)"
            return ShoppingItem(name: total.name,
                                detail: detail,
                                category: total.category,
                                isChecked: previouslyChecked.contains(total.name),
                                isCustom: false)
        }

        shoppingItems = generated + custom
    }

    func toggleChecked(at index: Int) {
        shoppingItems[index].isChecked.toggle()
    }

    func addCustomItem(name: String) {
        shoppingItems.append(ShoppingItem(name: name, detail: "", category: .other, isChecked: false, isCustom: true))
    }

    func deleteShoppingItem(at index: Int) {
        shoppingItems.remove(at: index)
    }

    func clearCompleted() {
        shoppingItems.removeAll { $0.isChecked }
    }

    // MARK: Sample data

    private static func makeSampleRecipes() -> [Recipe] {
        func ing(_ name: String, _ amount: Double, _ unit: String, _ category: IngredientCategory) -> Ingredient {
            Ingredient(name: name, amount: amount, unit: unit, category: category)
        }

        return [
            Recipe(id: 1, name: "Veggie Omelette", cuisine: "American", prepMinutes: 15, servings: 1,
                   symbolName: "fork.knife",
                   ingredients: [
                    ing("Eggs", 3, "", .proteins),
                    ing("Spinach", 1, "cup", .produce),
                    ing("Cheddar cheese", 0.25, "cup", .dairy),
                    ing("Butter", 1, "tbsp", .dairy)
                   ],
                   instructions: [
                    "Whisk the eggs with a pinch of salt.",
                    "Melt the butter in a pan over medium heat and add the spinach until wilted.",
                    "Pour in the eggs, sprinkle with cheese, and fold when set."
                   ]),
            Recipe(id: 2, name: "Overnight Oats", cuisine: "American", prepMinutes: 10, servings: 1,
                   symbolName: "cup.and.saucer.fill",
                   ingredients: [
                    ing("Rolled oats", 0.5, "cup", .pantry),
                    ing("Milk", 0.5, "cup", .dairy),
                    ing("Banana", 1, "", .produce),
                    ing("Honey", 1, "tbsp", .pantry)
                   ],
                   instructions: [
                    "Stir the oats, milk, and honey together in a jar.",
                    "Refrigerate overnight.",
                    "Top with sliced banana before serving."
                   ]),
            Recipe(id: 3, name: "Chicken Caesar Wrap", cuisine: "American", prepMinutes: 20, servings: 2,
                   symbolName: "leaf.fill",
                   ingredients: [
                    ing("Chicken breast", 1, "lb", .proteins),
                    ing("Romaine lettuce", 1, "head", .produce),
                    ing("Tortillas", 2, "", .pantry),
                    ing("Caesar dressing", 3, "tbsp", .pantry),
                    ing("Parmesan", 0.25, "cup", .dairy)
                   ],
                   instructions: [
                    "Season and pan-cook the chicken for 6 minutes per side, then slice.",
                    "Toss chopped romaine with dressing and parmesan.",
                    "Fill the tortillas with chicken and salad, then roll tightly."
                   ]),
            Recipe(id: 4, name: "Spaghetti Marinara", cuisine: "Italian", prepMinutes: 30, servings: 4,
                   symbolName: "fork.knife",
                   ingredients: [
                    ing("Spaghetti", 12, "oz", .pantry),
                    ing("Marinara sauce", 2, "cup", .pantry),
                    ing("Garlic", 3, "cloves", .produce),
                    ing("Parmesan", 0.25, "cup", .dairy)
                   ],
                   instructions: [
                    "Boil the spaghetti until al dente.",
                    "Saute the garlic, add the marinara, and simmer for 10 minutes.",
                    "Toss the pasta in the sauce and top with parmesan."
                   ]),
            Recipe(id: 5, name: "Chicken Stir-Fry", cuisine: "Asian", prepMinutes: 25, servings: 3,
                   symbolName: "flame.fill",
                   ingredients: [
                    ing("Chicken breast", 1, "lb", .proteins),
                    ing("Broccoli", 2, "cup", .produce),
                    ing("Soy sauce", 3, "tbsp", .pantry),
                    ing("Rice", 1, "cup", .pantry),
                    ing("Garlic", 2, "cloves", .produce)
                   ],
                   instructions: [
                    "Cook the rice according to the package.",
                    "Stir-fry the chicken and garlic in a hot pan until browned.",
                    "Add the broccoli and soy sauce and cook 4 more minutes. Serve over rice."
                   ]),
            Recipe(id: 6, name: "Beef Tacos", cuisine: "Mexican", prepMinutes: 25, servings: 4,
                   symbolName: "flame.fill",
                   ingredients: [
                    ing("Ground beef", 1, "lb", .proteins),
                    ing("Taco shells", 8, "", .pantry),
                    ing("Cheddar cheese", 0.5, "cup", .dairy),
                    ing("Tomato", 2, "", .produce),
                    ing("Romaine lettuce", 0.5, "head", .produce)
                   ],
                   instructions: [
                    "Brown the beef with taco seasoning.",
                    "Warm the taco shells in the oven for 3 minutes.",
                    "Fill with beef, tomato, lettuce, and cheese."
                   ]),
            Recipe(id: 7, name: "Veggie Fried Rice", cuisine: "Asian", prepMinutes: 20, servings: 2,
                   symbolName: "leaf.fill",
                   ingredients: [
                    ing("Rice", 1, "cup", .pantry),
                    ing("Eggs", 2, "", .proteins),
                    ing("Soy sauce", 2, "tbsp", .pantry),
                    ing("Mixed vegetables", 1, "cup", .produce),
                    ing("Garlic", 2, "cloves", .produce)
                   ],
                   instructions: [
                    "Use day-old rice if you have it.",
                    "Scramble the eggs in a hot pan and set aside.",
                    "Fry the garlic and vegetables, add the rice and soy sauce, then fold the eggs back in."
                   ]),
            Recipe(id: 8, name: "Greek Yogurt Parfait", cuisine: "American", prepMinutes: 5, servings: 1,
                   symbolName: "cup.and.saucer.fill",
                   ingredients: [
                    ing("Greek yogurt", 1, "cup", .dairy),
                    ing("Granola", 0.25, "cup", .pantry),
                    ing("Strawberries", 0.5, "cup", .produce),
                    ing("Honey", 1, "tbsp", .pantry)
                   ],
                   instructions: [
                    "Layer yogurt, strawberries, and granola in a glass.",
                    "Drizzle with honey."
                   ])
        ]
    }
}
