//
//  RootTabView.swift
//  MyFavor
//
//  Created by Jason Pepas on 1/22/26.
//

import SwiftUI


/// The tab bar.
struct RootTabView: View {
    var body: some View {
        TabView {
            NavigationStack(path: $_categoriesNavStackPath) {
                CategoriesView()
                    .navigationDestination(for: RootTabView.Route.self) { route in
                        _route(for: route)
                    }
            }
            .tabItem {
                Label("Cuisine", systemImage: "list.bullet")
            }

            NavigationStack(path: $_sectionsNavStackPath) {
                FeedView()
                    .navigationDestination(for: RootTabView.Route.self) { route in
                        _route(for: route)
                    }
            }
            .tabItem {
                Label("Feed", systemImage: "list.clipboard")
            }

            NavigationStack(path: $_favoriteMerchantsNavStackPath) {
                FavoriteMerchantsView()
                    .navigationDestination(for: RootTabView.Route.self) { route in
                        _route(for: route)
                    }
            }
            .tabItem {
                Label("Favorites", systemImage: "heart")
            }

            DeveloperView()
                .tabItem {
                    Label("Developer", systemImage: "hammer")
                }
        }
    }

    enum Route: Hashable {
        case category(BrowseJSON.CategoryJSON)
//        case menu(CategoryJSON.MerchantJSON)
        case menu(BrowseJSON.MerchantCarouselSectionJSON.MerchantJSON)
    }

    // MARK: Internals

    @State private var _categoriesNavStackPath: [Route] = []
    @State private var _sectionsNavStackPath: [Route] = []
    @State private var _favoriteMerchantsNavStackPath: [Route] = []

    private func _route(for route: RootTabView.Route) -> some View {
        Group {
            switch route {
            case .category(let category):
                CategoryView(categodyID: category.id, categoryName: category.name)
            case .menu(let merchant):
                MenuView(merchant: merchant)
            }
        }
    }
}
