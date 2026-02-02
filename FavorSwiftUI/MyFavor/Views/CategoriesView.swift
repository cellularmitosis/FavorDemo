//
//  CategoriesView.swift
//  MyFavor
//
//  Created by Jason Pepas on 1/17/26.
//

import SwiftUI
import Kingfisher


/// Displays a list of "categories" (e.g. "pizza", "burgers", etc).
struct CategoriesView: View {

    var body: some View {
        Group {
            switch _client.browseFetchState {
            case .empty:
                _makeEmptyView()

            case .loading:
                ProgressView()
                    .onAppear { print("BrowseView: .loading") }

            case .succeeded(let browse, _):
                let categories = _filtered(categories: browse.categories, using: _searchQuery)
                _makeSucceededView(categories: categories)

            case .failed(let error):
                _makeFailedView(error: error)
            }
        }
        .navigationTitle("Cuisine")
    }

    // MARK: Internals

    @Environment(FavorClient.self) private var _client

    @State private var _searchQuery: String = ""

    private func _filtered(categories: [BrowseJSON.CategoryJSON], using query: String) -> [BrowseJSON.CategoryJSON] {
        guard query.count > 0 else {
            return categories
        }
        return (categories).filter { category in
            category.name.range(of: query, options: [.caseInsensitive]) != nil
        }
    }

    @ViewBuilder
    private func _makeEmptyView() -> some View {
        Color.clear
            .onAppear {
                print("BrowseView: .empty")
                Task {
                    await _client.fetchBrowseIfNeeded()
                }
            }
    }

    @ViewBuilder
    private func _makeSucceededView(categories: [BrowseJSON.CategoryJSON]) -> some View {
        List {
            ForEach(categories) { category in
                NavigationLink(value:  RootTabView.Route.category(category)) {
                    CategoryCell(category: category)
                }
            }
        }
        .searchable(text: $_searchQuery, prompt: "Search")
        .onAppear { print("BrowseView: .success") }
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
                    await _client.fetchBrowseIfNeeded()
                }
            }
        }
        .onAppear { print("BrowseView: .failed") }
    }
}


/// A cell representing a category (e.g. "pizza").
struct CategoryCell: View {
    let category: BrowseJSON.CategoryJSON

    var body: some View {
        HStack {
            KFImage(category.images.card_image)
                .placeholder {
                    ProgressView()
                        .frame(width: 80, height: 80)
                }
                .fade(duration: 0.25)
                .resizable()
                .scaledToFill()
                .frame(width: 80, height: 80)
                .clipShape(.circle)

            Text(category.name)
                .font(.title3)
                .bold()
                .padding([.leading], 8)
        }
    }
}
