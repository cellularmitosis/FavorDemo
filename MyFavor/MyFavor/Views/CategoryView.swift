//
//  CategoryView.swift
//  MyFavor
//
//  Created by Jason Pepas on 1/17/26.
//

import SwiftUI
import Kingfisher


/// Displays the restaurants in a particular "category" (e.g. "pizza").
struct CategoryView: View {
    let categodyID: String
    let categoryName: String

    // Use this closure when this View is used within a UIKit context
    var didSelectMerchant: ((BrowseJSON.MerchantCarouselSectionJSON.MerchantJSON) -> Void)? = nil

    var body: some View {
        let container = _client.categoryFetchStateContainer(forCategoryID: categodyID)
        Group {
            switch container.fetchState {
            case .empty:
                _makeEmptyView()

            case .loading:
                ProgressView()

            case .succeeded(let category, _):
                _makeSucceededView(category: category)

            case .failed(let error):
                _makeFailedView(error: error)
            }
        }
        .navigationTitle(categoryName)
    }

    // MARK: Internals

    @Environment(FavorClient.self) private var _client

    @ViewBuilder
    private func _makeEmptyView() -> some View {
        Color.clear
            .onAppear {
                Task {
                    await _client.fetchCategoryIfNeeded(categoryID: categodyID)
                }
            }
    }

    @ViewBuilder
    private func _makeSucceededView(category: CategoryJSON) -> some View {
        List {
            ForEach(category.merchants) { merchant in
                if let didSelectMerchant {
                    // for use within a UINavigationController context:
                    Button {
                        didSelectMerchant(merchant)
                    } label: {
                        MerchantCell(merchant: merchant)
                    }
                } else {
                    // for use within a SwiftUI context:
                    NavigationLink(value: RootTabView.Route.menu(merchant)) {
                        MerchantCell(merchant: merchant)
                    }
                }
            }
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
                    await _client.fetchCategoryIfNeeded(categoryID: categodyID)
                }
            }
        }
    }
}


/// A cell representing a restaurant.
struct MerchantCell: View {
//    let merchant: CategoryJSON.MerchantJSON
    let merchant: BrowseJSON.MerchantCarouselSectionJSON.MerchantJSON

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Rectangle()
                .fill(.gray.opacity(0.2))
                .frame(maxWidth: .infinity)
                .aspectRatio(16/9, contentMode: .fit)
                .overlay {
                    KFImage(merchant.image_url)
                        .fade(duration: 0.25)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                }
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text("\(merchant.name)").bold()
        }
    }
}
