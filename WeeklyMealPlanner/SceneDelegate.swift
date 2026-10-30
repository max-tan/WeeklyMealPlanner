import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = makeRootViewController()
        window.makeKeyAndVisible()
        self.window = window
    }

    /// Three tabs, each wrapped in its own navigation controller.
    private func makeRootViewController() -> UIViewController {
        let planNav = makeNavigationController(
            root: WeeklyPlanViewController(),
            title: "Plan",
            symbol: "calendar")
        let recipesNav = makeNavigationController(
            root: RecipeListViewController(),
            title: "Recipes",
            symbol: "book.fill")
        let favoritesNav = makeNavigationController(
            root: FavoritesViewController(),
            title: "Favorites",
            symbol: "heart.fill")

        let tabBarController = UITabBarController()
        tabBarController.viewControllers = [planNav, recipesNav, favoritesNav]
        tabBarController.tabBar.tintColor = .systemOrange
        return tabBarController
    }

    private func makeNavigationController(root: UIViewController, title: String, symbol: String) -> UINavigationController {
        let navigationController = UINavigationController(rootViewController: root)
        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: symbol), selectedImage: nil)
        return navigationController
    }
}
