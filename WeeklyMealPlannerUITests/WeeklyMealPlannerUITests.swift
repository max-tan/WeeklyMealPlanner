import XCTest

/// Walks through all six Milestone 1 screens on launch and attaches a screenshot
/// of each one to the test result, so CI can export them as build artifacts.
final class WeeklyMealPlannerUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCaptureAllScreens() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.navigationBars["This Week"].waitForExistence(timeout: 10))
        attach(app, "01-WeeklyPlan")

        app.buttons["Shopping List"].tap()
        XCTAssertTrue(app.navigationBars["Shopping List"].waitForExistence(timeout: 5))
        attach(app, "05-ShoppingList")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        XCTAssertTrue(app.navigationBars["This Week"].waitForExistence(timeout: 5))
        app.buttons["Add Meal"].tap()
        XCTAssertTrue(app.navigationBars["Add Meal"].waitForExistence(timeout: 5))
        attach(app, "04-AddMeal")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        app.tabBars.buttons["Recipes"].tap()
        XCTAssertTrue(app.navigationBars["Recipes"].waitForExistence(timeout: 5))
        attach(app, "02-RecipeList")

        app.tables.cells.firstMatch.tap()
        XCTAssertTrue(app.scrollViews.firstMatch.waitForExistence(timeout: 5))
        attach(app, "03-RecipeDetail")

        app.tabBars.buttons["Favorites"].tap()
        XCTAssertTrue(app.navigationBars["Favorites"].waitForExistence(timeout: 5))
        attach(app, "06-Favorites")
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
