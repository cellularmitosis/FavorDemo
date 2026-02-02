//
//  APITypes.swift
//  MyFavor
//
//  Created by Jason Pepas on 1/17/26.
//

import Foundation


/// Unfortunately, some URLs are empty string rather than null, so we need a workaround for decoding.
@propertyWrapper
nonisolated
struct LossyURL: Decodable, Equatable {
    var wrappedValue: URL?

    enum CodingKeys: CodingKey {
        case wrappedValue
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            wrappedValue = nil
        } else if let s = try? container.decode(String.self) {
            if s.isEmpty {
                wrappedValue = nil
                return
            } else {
                wrappedValue = URL(string: s)
            }
        }
    }
}


/// Returned by /page-layouts/v2/browse
nonisolated
struct BrowseJSON: Decodable, Equatable {
    let categories: [CategoryJSON] // e.g. "Pizza", "Burgers", etc
    let filters: [FilterJSON]
    let sections: [SectionJSON] // e.g. "For you", "Featured on Favor", etc
    let is_empty: Bool

    var merchantSections: [MerchantCarouselSectionJSON] {
        sections.compactMap {
            if case let .merchantCarousel(merchantSection) = $0 {
                return merchantSection
            } else {
                return nil
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case categories, filters, sections, is_empty
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.categories = try container.decode([CategoryJSON].self, forKey: .categories)
        self.filters = try container.decode([FilterJSON].self, forKey: .filters)
        self.sections = try container.decode([SectionJSON].self, forKey: .sections).filter {
            if case .unknown = $0 {
                return false
            } else {
                return true
            }
        }
        self.is_empty = try container.decode(Bool.self, forKey: .is_empty)
    }

    struct CategoryJSON: Decodable, Equatable, Hashable, Identifiable {
        let id: String
        let name: String
        let slug: String
        let category_pinned: Bool
        let category_pinned_date: Date?
        let icon_url: URL
        let images: ImagesJSON
//        let merchants: ???

        struct ImagesJSON: Decodable, Equatable, Hashable {
            let search_icon: URL
            let hero_image: URL
            let card_image: URL
            let card_mobile_image: URL
        }
    }

    struct FilterJSON: Decodable, Equatable {
        let name: String
        let type: String
        let values: [ValueJSON]
        let icon_url: URL

        struct ValueJSON: Decodable, Equatable {
            let display_name: String
            let value: Int
        }
    }

    enum SectionJSON: Decodable, Equatable, Identifiable {
        case heroCarousel(_: HeroCarouselSectionJSON)
        case merchantCarousel(_: MerchantCarouselSectionJSON)
        case unknown

        var id: String {
            switch self {
            case .heroCarousel(let heroCarousel):
                return heroCarousel.id
            case .merchantCarousel(let merchantCarousel):
                return merchantCarousel.id
            case .unknown:
                return "unknown"
            }
        }

        enum CodingKeys: String, CodingKey {
            case layout
        }

        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let layout = try? container.decode(String.self, forKey: .layout)
            switch layout {
            case "hero_carousel":
                self = .heroCarousel(try HeroCarouselSectionJSON(from: decoder))
            case "merchant_carousel":
                self = .merchantCarousel(try MerchantCarouselSectionJSON(from: decoder))
            default:
                self = .unknown
            }
        }
    }

    struct HeroCarouselSectionJSON: Decodable, Equatable {
        let heroes: [HeroJSON]
        let layout: String
        let hero_type: String
        let web_hero_type: String

        var id: String {
            "Heroes"
        }

        struct HeroJSON: Decodable, Equatable {
            @LossyURL var background_image_url: URL?
            @LossyURL var web_hero_image_url: URL?
            let title: String
            let subtitle: String?
            let eyebrow: String?
            let cta: String
            let image_url: URL
            let colors: ColorJSON
//            @LossyURL var link: URL?
            let display_type: String

            struct ColorJSON: Decodable, Equatable {
                let background: String
                let eyebrow: String
                let title: String
                let subtitle: String?
                let cta: String
            }
        }
    }

    struct MerchantCarouselSectionJSON: Decodable, Equatable, Identifiable {
        let layout: String
        let title: String
        let category_id: Int?
        let slug: String?
        let merchants: [MerchantJSON]
        let merchant_link: String?
        let merchant_link_type: String?
        let merchant_link_id: Int?

        var id: String {
            title
        }

        struct MerchantJSON: Codable, Equatable, Hashable, Identifiable {
            let id: Int
            let franchise_id: Int
            let name: String
            let is_open: Bool
            let image_url: URL
            let distance_display_string: String
            let delivery_fee: DeliveryFeeJSON
            let origin_tracking: TrackingJSON
            let badge: BadgeJSON?
            let flavor_text: String?
            let rating: Double?

            struct BadgeJSON: Codable, Equatable, Hashable {
                let text: String
                let theme: String
            }

            struct DeliveryFeeJSON: Codable, Equatable, Hashable {
                let display_delivery_fee: String
                let strike_through_fee: String?
                let is_loyalty: Bool
                let text_color: String
            }

            struct TrackingJSON: Codable, Equatable, Hashable {
                let category_id: String?
                let collection_type: String?
                let filter_ids: [String]?
                let collection_id: String?
            }
        }
    }
}


/// Returned by /api/v6/merchants/:id
nonisolated
struct MerchantJSON: Decodable, Equatable {
    let id: String?
    let name: String
    let has_expanded_menu: String
    let franchise_id: String
    let market_id: String
    let phone: String
    let address: String
    let city: String
    let state: String
    let zipcode: String
    let lat: String
    let lng: String
    let is_car_only: Bool
    let live: Bool
    let primetime_exempt: Bool
    let is_open: Bool
    let merchant_hours: MerchantHoursJSON
    let display_delivery_fee: String
    let display_delivery_fee_2: String
    let is_loyalty_discount: Bool
    let display_price_range: String
    let display_image_url: URL
    let display_icon_url: URL
    let display_string_1: String
    let display_string_2: String
    let price_range: Int
//    let notes: ???
//    let store_id: ???
//    let order_number: ???
    let score: String
    let retailer_image: URL
    let is_masked: Bool
    let formatted_delivery_fee: String
    let base_delivery_fee: Int
//    let distance: ???
    let display_customer_contact_preference: Bool
    let is_integrated: Bool
    let supports_integrated_failover: Bool
    let is_killswitched: Bool
//    let geofence: ???
    let is_local: Bool
    let scheduling_enabled: Bool

    struct MerchantHoursJSON: Decodable, Equatable {
        let is_open: Bool
        let schedule: [ScheduleJSON]

        struct ScheduleJSON: Decodable, Equatable {
            let open: DayTimeJSON
            let close: DayTimeJSON

            struct DayTimeJSON: Decodable, Equatable {
                let day: String
                let time: String
            }
        }
    }
}


/// Returned by /menu-hydration/public/v2/locations/:id/menu_url
nonisolated
struct MenuURLJSON: Decodable, Equatable {
    let menu_url: String // e.g. "locations/10370/menu/4yhZd9QI7T1VryE3rcx_kfyzVn8wJHzW2A8Pn89LZhE"
//    let promotion_lists: [???]
//    let features: ???
//    let promotions: ???
}


/// Returned by /menu-hydration/public/v2/locations/:id/menu/:id/overview
nonisolated
struct MenuOverviewJSON: Decodable, Equatable, Hashable {
    let id: Int
    let option_groups: [OptionGroupJSON]?
    let option_items: [OptionItemJSON]?
    let menu_items: [MenuItemJSON]
    let sub_menus: [SubMenuJSON]

    struct OptionGroupJSON: Decodable, Equatable, Identifiable, Hashable {
        let id: String
        let name: String?
        let options: [String]
        let required_description: String?
        let min_selectable: Int?
        let max_selectable: Int?
    }

    struct OptionItemJSON: Decodable, Equatable, Identifiable, Hashable {
        let base_price: Int
        let id: String
        let is_quantifiable: Bool?
        let name: String
        let option_groups: [String]?
        let price: Int
        let min_item_display_price: Int
    }

    struct MenuItemJSON: Decodable, Equatable, Identifiable, Hashable {
        let base_price: Int
        let description: String?
        let id: String
        let is_quantifiable: Bool
        let name: String
        let option_groups: [String]?
        let price: Int
        let min_item_display_price: Int
        let sub_menu_ids: [String]
    }

    struct SubMenuJSON: Decodable, Equatable, Identifiable, Hashable {
        let id: String
        let name: String
        let sections: [SectionJSON]

        struct SectionJSON: Decodable, Equatable, Identifiable, Hashable {
            let id: String
            let name: String
            let item_count: Int
            let menu_items: [String]
        }
    }
}


/// Returned by /page-layouts/v2/filters/collection?cuisine=:id
nonisolated
struct CategoryJSON: Decodable, Equatable {
    let title: String
//    let merchants: [MerchantJSON]
    let merchants: [BrowseJSON.MerchantCarouselSectionJSON.MerchantJSON]
    let layout: String
    let pagination: PaginationJSON

    struct PaginationJSON: Decodable, Equatable {
        let page_size: Int
        let page: Int
        let total: Int
    }

//    struct MerchantJSON: Decodable, Equatable, Identifiable, Hashable {
//        let id: Int
//        let franchise_id: Int
//        let name: String
//        let is_open: Bool
//        let image_url: URL
//        let distance_display_string: String
//        let delivery_fee: DeliveryFeeJSON
//        let origin_tracking: OriginTrackingJSON
//        let badge: BadgeJSON?
////        let flavor_text: ???
//        let rating: Double?
//
//        struct DeliveryFeeJSON: Decodable, Equatable, Hashable {
//            let display_delivery_fee: String
//            let strike_through_fee: String?
//            let is_loyalty: Bool
//            let text_color: String
//        }
//
//        struct OriginTrackingJSON: Decodable, Equatable, Hashable {
////            let category_id: ???
//            let collection_type: String
////            let filter_ids: ???
////            let collection_id: ???
//        }
//
//        struct BadgeJSON: Decodable, Equatable, Hashable {
//            let text: String
//            let theme: String
//        }
//    }
}
