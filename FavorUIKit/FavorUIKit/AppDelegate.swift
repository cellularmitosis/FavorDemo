//
//  AppDelegate.swift
//  FavorUIKit
//
//  Created by Jason Pepas on 2/1/26.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var client: FavorClient
    var favoritesStore: FavoriteMerchantsStore
    var reqlog: RequestLog

    override init() {
        self.reqlog = RequestLog()
        self.client = FavorClient(location: .momAndDadsHouse, reqlog: self.reqlog)
        self.favoritesStore = FavoriteMerchantsStore()
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow()
        window?.rootViewController = _makeTabController()
        window?.makeKeyAndVisible()
        return true
    }

    // MARK: Internals

    private func _makeTabController() -> UITabBarController {
        // cuisine tab
        let categoriesVC = CategoriesViewController(client: client)
        categoriesVC.delegate = self
        let categoriesNav = UINavigationController(rootViewController: categoriesVC)
        categoriesNav.tabBarItem.title = "Cuisine"
        categoriesNav.tabBarItem.image = UIImage(systemName: "list.bullet")
        categoriesNav.tabBarItem.selectedImage = UIImage(systemName: "list.bullet.fill")

        // feed tab
        let feedNav = UINavigationController()
        let feedView = FeedView(didSelectMerchant: { [weak self] in
            self?._didSelect(merchant: $0, fromNav: feedNav)
        })
            .environment(client)
            .environment(favoritesStore)
        let feedVC = UIHostingController(rootView: feedView)
        feedNav.viewControllers = [feedVC]
        feedNav.tabBarItem.title = "Feed"
        feedNav.tabBarItem.image = UIImage(systemName: "list.clipboard")
        feedNav.tabBarItem.selectedImage = UIImage(systemName: "list.clipboard.fill")

        // favorites tab
        let favNav = UINavigationController()
        let favView = FavoriteMerchantsView { [weak self] in
            self?._didSelect(merchant: $0, fromNav: favNav)
        }
            .environment(favoritesStore)
        let favVC = UIHostingController(rootView: favView)
        favNav.viewControllers = [favVC]
        favNav.tabBarItem.title = "Favorites"
        favNav.tabBarItem.image = UIImage(systemName: "heart")
        favNav.tabBarItem.selectedImage = UIImage(systemName: "heart.fill")

        // developer tab
        let devView = DeveloperView()
            .environment(reqlog)
        let devVC = UIHostingController(rootView: devView)
        devVC.tabBarItem.title = "Developer"
        devVC.tabBarItem.image = UIImage(systemName: "hammer")
        devVC.tabBarItem.image = UIImage(systemName: "hammer.fill")

        let tabVC = UITabBarController()
        tabVC.viewControllers = [categoriesNav, feedNav, favNav, devVC]
        return tabVC
    }
}


import SwiftUI

extension AppDelegate: CategoriesViewControllerDelegate {

    func didSelect(category: BrowseJSON.CategoryJSON, from fromVC: CategoriesViewController) {
        guard let navC = fromVC.navigationController else { return }

        let categoryView = CategoryView(
            categodyID: category.id,
            categoryName: category.name,
            didSelectMerchant: { [weak self] in
                self?._didSelect(merchant: $0, fromNav: navC)
            }
        )
            .environment(client)

        let categoryVC = UIHostingController(rootView: categoryView)
        fromVC.navigationController?.pushViewController(categoryVC, animated: true)
    }

    private func _didSelect(merchant: BrowseJSON.MerchantCarouselSectionJSON.MerchantJSON, fromNav: UINavigationController) {
        let menuView = MenuView(merchant: merchant)
            .environment(self.client)
            .environment(self.favoritesStore)
        let merchantVC = UIHostingController(rootView: menuView)
        fromNav.pushViewController(merchantVC, animated: true)
    }
}
