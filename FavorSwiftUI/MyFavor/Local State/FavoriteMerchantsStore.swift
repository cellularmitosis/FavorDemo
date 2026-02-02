//
//  FavoritesStore.swift
//  MyFavor
//
//  Created by Jason Pepas on 1/22/26.
//

import Foundation
import Observation

//fileprivate let _log: (String) -> Void = { }
fileprivate let _log: (String) -> Void = { print($0) }


/// Disk-backed storage for a list of favorite restaurants.
@Observable
class FavoriteMerchantsStore {

    private(set) var merchants: [BrowseJSON.MerchantCarouselSectionJSON.MerchantJSON]

    init() {
        merchants = Self._load()
    }

    func add(merchant: BrowseJSON.MerchantCarouselSectionJSON.MerchantJSON) {
        _log("> FavoriteMerchantsStore: add \(merchant.name)")
        if merchants.contains(where: { $0.id == merchant.id }) {
            return
        }
        var newMerchants = merchants
        newMerchants.append(merchant)
        newMerchants.sort { lhs, rhs in
            lhs.name < rhs.name
        }
        Self._store(favorites: newMerchants)
        merchants = newMerchants
    }

    func remove(merchant: BrowseJSON.MerchantCarouselSectionJSON.MerchantJSON) {
        _log("> FavoriteMerchantsStore: remove \(merchant.name)")
        var newMerchants = merchants
        newMerchants.removeAll { $0.id == merchant.id }
        Self._store(favorites: newMerchants)
        merchants = newMerchants
    }

    func contains(merchant: BrowseJSON.MerchantCarouselSectionJSON.MerchantJSON) -> Bool {
        return merchants.contains(where: { $0.id == merchant.id })
    }

    // MARK: Internals

    private static func _load() -> [BrowseJSON.MerchantCarouselSectionJSON.MerchantJSON] {
        guard let data = UserDefaults.standard.data(forKey: "favorites") else {
            return []
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            let obj = try decoder.decode([BrowseJSON.MerchantCarouselSectionJSON.MerchantJSON].self, from: data)
            return obj
        } catch {
            print(error)
            UserDefaults.standard.removeObject(forKey: "favorites")
            return []
        }
    }

    private static func _store(favorites: [BrowseJSON.MerchantCarouselSectionJSON.MerchantJSON]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        do {
            let data = try encoder.encode(favorites)
            UserDefaults.standard.set(data, forKey: "favorites")
        } catch {
            print(error)
            UserDefaults.standard.removeObject(forKey: "favorites")
        }
    }
}
