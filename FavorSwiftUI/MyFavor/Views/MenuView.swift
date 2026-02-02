//
//  MenuView.swift
//  MyFavor
//
//  Created by Jason Pepas on 1/18/26.
//

import SwiftUI


/// Displays the menu details of a restaurant.
struct MenuView: View {
    let merchant: BrowseJSON.MerchantCarouselSectionJSON.MerchantJSON

    var body: some View {
        let container = _client.menuFetchStateContainer(forMerchantID: merchant.id)
        Group {
            switch container.fetchState {
            case .empty:
                _makeEmptyView()

            case .loading:
                ProgressView()

            case .succeeded(let content, _):
                _makeSucceededView(content: content)

            case .failed(let error):
                _makeFailedView(error: error)
            }
        }
        .navigationTitle(merchant.name)
        .toolbar {
            _makeFavoriteButton()
        }
    }

    // MARK: Internals

    @Environment(FavorClient.self) private var _client
    @Environment(FavoriteMerchantsStore.self) private var _favoritesStore

    @ViewBuilder
    private func _makeEmptyView() -> some View {
        Color.clear
            .onAppear {
                Task {
                    await _client.fetchMenuIfNeeded(merchantID: merchant.id)
                }
            }
    }

    private func _makeMenuItemLookupTable(content: MenuOverviewJSON) -> [String:MenuOverviewJSON.MenuItemJSON] {
        var lookup: [String: MenuOverviewJSON.MenuItemJSON] = [:]
        for item in content.menu_items {
            lookup[item.id] = item
        }
        return lookup
    }

    @ViewBuilder
    private func _makeSucceededView(content: MenuOverviewJSON) -> some View {
        let lookup = _makeMenuItemLookupTable(content: content)
        if content.sub_menus.count > 0 {
            let allSections = content.sub_menus.flatMap { $0.sections }
            List {
                ForEach(allSections) { section in
                    Section {
                        ForEach(section.menu_items, id: \.self) { menuItemID in
                            if let menuItem = lookup[menuItemID] {
                                MenuItemCell(menuItem: menuItem)
                            }
                        }
                    } header: {
                        Text(section.name)
                            .font(.title2)
                            .bold()
                    }
                }
            }
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func _makeFailedView(error: Error) -> some View {
        ContentUnavailableView {
            Label("Error", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error.localizedDescription)
        } actions: {
            Button("Refresh") {
                Task {
                    await _client.fetchMenuIfNeeded(merchantID: merchant.id)
                }
            }
        }
    }

    @ToolbarContentBuilder
    private func _makeFavoriteButton() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("", systemImage: _favoritesStore.contains(merchant: merchant) ? "heart.fill" : "heart") {
                if _favoritesStore.contains(merchant: merchant) {
                    _favoritesStore.remove(merchant: merchant)
                } else {
                    _favoritesStore.add(merchant: merchant)
                }
            }
        }
    }
}


struct MenuItemCell: View {
    let menuItem: MenuOverviewJSON.MenuItemJSON
    var body: some View {
        HStack {
            Text(menuItem.name)
            Spacer()
            Text(Double(menuItem.price)/100, format: .currency(code: "USD"))
        }
    }
}
