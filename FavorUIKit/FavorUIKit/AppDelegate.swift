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

    override init() {
        self.client = FavorClient(location: .momAndDadsHouse, reqlog: RequestLog())
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow()

        _categoriesVC = CategoriesViewController(client: client)
        _categoriesVC.delegate = self
        let categoriesNav = UINavigationController(rootViewController: _categoriesVC)
        categoriesNav.tabBarItem.title = "Cuisine"
        categoriesNav.tabBarItem.image = UIImage(systemName: "star")
        categoriesNav.tabBarItem.selectedImage = UIImage(systemName: "star.fill")

        let tabVC = UITabBarController()
        tabVC.viewControllers = [categoriesNav]
        window?.rootViewController = tabVC
        window?.makeKeyAndVisible()
        return true
    }

    private var _categoriesVC: CategoriesViewController!
}


import SwiftUI

extension AppDelegate: CategoriesViewControllerDelegate {
    func didSelect(category: BrowseJSON.CategoryJSON, from: CategoriesViewController) {
        let vc = UIHostingController(
            rootView: CategoryView(categodyID: category.id, categoryName: category.name)
                .environment(client)
        )
        _categoriesVC.navigationController?.pushViewController(vc, animated: true)
    }
}
