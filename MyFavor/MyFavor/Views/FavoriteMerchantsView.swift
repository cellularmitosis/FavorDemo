//
//  FavoriteMerchantsView.swift
//  MyFavor
//
//  Created by Jason Pepas on 1/22/26.
//

import SwiftUI


/// The "favorites" tab.
struct FavoriteMerchantsView: View {
    var body: some View {
        List {
            ForEach(_favoritesStore.merchants) { merchant in
                NavigationLink(value: RootTabView.Route.menu(merchant)) {
                    MerchantCell(merchant: merchant)
                }
            }
        }
        .navigationTitle("Favorites")
    }

    // MARK: Internals

    @Environment(FavoriteMerchantsStore.self) private var _favoritesStore
}
