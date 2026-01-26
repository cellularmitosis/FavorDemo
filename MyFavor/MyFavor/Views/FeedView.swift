//
//  FeedView.swift
//  MyFavor
//
//  Created by Jason Pepas on 1/22/26.
//

import SwiftUI


/// The "feed" tab.
struct FeedView: View {
    var body: some View {
        Group {
            switch _client.browseFetchState {
            case .empty:
                _makeEmptyView()

            case .loading:
                ProgressView()
                    .onAppear() {
                        print("SectionsView: .loading")
                    }

            case .succeeded(let content, _):
                _makeSucceededView(content: content)

            case .failed(let error):
                _makeFailedView(error: error)
            }
        }
        .navigationTitle("Feed")
    }

    // MARK: Internals

    @Environment(FavorClient.self) private var _client

    private func _makeEmptyView() -> some View {
        Color.clear
            .onAppear() {
                print("SectionsView: .empty")
                Task {
                    await _client.fetchBrowseIfNeeded()
                }
            }
    }

    private func _makeSucceededView(content: BrowseJSON) -> some View {
        List {
            ForEach(content.merchantSections) { section in
                // e.g. "For you", "Featured on Favor"
                Section {
                    ForEach(section.merchants) { merchant in
                        NavigationLink(value: RootTabView.Route.menu(merchant)) {
                            MerchantCell(merchant: merchant)
                        }
                    }
                } header: {
                    Text(section.title)
                        .font(.title2)
                        .bold()
                }
            }
        }
    }

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
    }
}
