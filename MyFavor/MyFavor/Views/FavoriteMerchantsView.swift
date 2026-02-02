//
//  FavoriteMerchantsView.swift
//  MyFavor
//
//  Created by Jason Pepas on 1/22/26.
//

import SwiftUI


/// The "favorites" tab.
struct FavoriteMerchantsView: View {

    // Use this closure when this View is used within a UIKit context
    var didSelectMerchant: ((BrowseJSON.MerchantCarouselSectionJSON.MerchantJSON) -> Void)? = nil

    var body: some View {
        List {
            ForEach(_favoritesStore.merchants) { merchant in
                if let didSelectMerchant {
                    Button {
                        didSelectMerchant(merchant)
                    } label: {
                        MerchantCell(merchant: merchant)
                    }
                } else {
                    NavigationLink(value: RootTabView.Route.menu(merchant)) {
                        MerchantCell(merchant: merchant)
                    }
                }
            }
        }
        .navigationTitle("Favorites")
    }

    // MARK: Internals

    @Environment(FavoriteMerchantsStore.self) private var _favoritesStore
}
