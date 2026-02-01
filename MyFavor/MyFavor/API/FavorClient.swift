//
//  APIClient.swift
//  FavorAPI
//
//  Created by Jason Pepas on 1/16/26.
//

import Foundation
import Observation

//fileprivate let _log: (String) -> Void = { }
fileprivate let _log: (String) -> Void = { print($0) }


struct GeoLocation: Codable, Equatable {
    let latitude: Double
    let longitude: Double

    static let favorHQ = GeoLocation(latitude: 30.2599563, longitude: -97.7147446)
    static let myHouse = GeoLocation(latitude: 30.2787973, longitude: -98.0527945)
    static let momAndDadsHouse = GeoLocation(latitude: 33.22473069, longitude: -96.71386319)
}


/// A caching, request-deduping Favor API client.
@Observable
class FavorClient {
    var baseURL: URL
    var jwt: String?
    var location: GeoLocation
    var reqlog: RequestLog?

    static let ttl: TimeInterval = 5 * 60

    init(
        baseURL: URL = URL(string: "https://api.askfavor.com")!,
        jwt: String? = nil,
        location: GeoLocation = .favorHQ,
        reqlog: RequestLog? = nil
    ) {
        self.baseURL = baseURL
        self.jwt = jwt
        self.location = location
        self.reqlog = reqlog
    }

    enum FetchState<T: Equatable>: Equatable {
        case empty
        case loading
        case succeeded(content: T, incept: Date)
        case failed(error: Error)

        /// Note: this ignores the associated error when comparing two .failed cases.
        static func == (lhs: FavorClient.FetchState<T>, rhs: FavorClient.FetchState<T>) -> Bool {
            switch (lhs, rhs) {
            case (.empty, .empty), (.loading, .loading):
                return true
            case (.succeeded(let a, let ad), .succeeded(let b, let bd)):
                return a == b && ad == bd
            case (.failed, .failed):
                return true
            default:
                return false
            }
        }
    }

    // MARK: Browse (/page-layouts/v2/browse)

    private(set) var browseFetchState: FetchState<BrowseJSON> = .empty

    /// The 'browse' endpoint returns categories (e.g. "Pizza"), filters, and sections ("For you").
    func fetchBrowseIfNeeded() async {
        if case .succeeded(_, let incept) = browseFetchState,
           Date().timeIntervalSince(incept) <= Self.ttl
        {
            return
        }
        if case .loading = browseFetchState { return }

        browseFetchState = .loading
        do {
            let jwt = try await _ensureGuestJWT()
            let (browse, _) = try await _getBrowse(baseURL: baseURL, jwt: jwt, location: location, reqlog: reqlog)
            browseFetchState = .succeeded(content: browse, incept: Date())
        } catch {
            _log("> fetchBrowseIfNeeded: -> .failed: \(error)")
            browseFetchState = .failed(error: error)
        }
    }

    // MARK: Category (/page-layouts/v2/filters/collection?cuisine=:id)

    @Observable
    class CategoryFetchStateContainer {
        let id: String
        var fetchState: FetchState<CategoryJSON> = .empty
        init(id: String) {
            self.id = id
        }
    }

    private var _categoryFetchStates: [String: CategoryFetchStateContainer] = [:]

    func categoryFetchStateContainer(forCategoryID id: String) -> CategoryFetchStateContainer {
        if let container = _categoryFetchStates[id] {
            return container
        } else {
            let container = CategoryFetchStateContainer(id: id)
            _categoryFetchStates[id] = container
            return container
        }
    }

    /// Returns a "category" (e.g. "pizza", "burgers")
    func fetchCategoryIfNeeded(categoryID id: String) async {
        let container = categoryFetchStateContainer(forCategoryID: id)
        if case .succeeded(_, let incept) = container.fetchState,
           Date().timeIntervalSince(incept) <= FavorClient.ttl
        {
            return
        }
        if case .loading = container.fetchState { return }

        container.fetchState = .loading
        do {
            let jwt = try await _ensureGuestJWT()
            let (category, _) = try await _getCategory(baseURL: baseURL, jwt: jwt, location: location, id: id, reqlog: reqlog)
            container.fetchState = .succeeded(content: category, incept: Date())
        } catch {
            _log("> fetchCategoryIfNeeded: -> .failed: \(error)")
            container.fetchState = .failed(error: error)
        }
    }

    // MARK: Menu (/menu-hydration/public/v2/:subpath/overview)

    @Observable
    class MenuFetchStateContainer {
        let id: Int
        var fetchState: FetchState<MenuOverviewJSON> = .empty
        init(id: Int) {
            self.id = id
        }
    }

    private var _menuFetchStates: [Int:MenuFetchStateContainer] = [:]

    func menuFetchStateContainer(forMerchantID id: Int) -> MenuFetchStateContainer {
        if let container = _menuFetchStates[id] {
            return container
        }
        let container = MenuFetchStateContainer(id: id)
        _menuFetchStates[id] = container
        return container
    }

    /// Returns the full menu details.
    func fetchMenuIfNeeded(merchantID id: Int) async {
        let container = menuFetchStateContainer(forMerchantID: id)
        if case .succeeded(_, let incept) = container.fetchState,
           Date().timeIntervalSince(incept) <= FavorClient.ttl
        {
            return
        }
        if case .loading = container.fetchState { return }

        container.fetchState = .loading
        do {
            let jwt = try await _ensureGuestJWT()
            let (menuUrlJson, _) = try await _getMenuURL(baseURL: baseURL, jwt: jwt, id: id, reqlog: reqlog)
            let (menu, _) = try await _getMenuOverview(baseURL: baseURL, jwt: jwt, subpath: menuUrlJson.menu_url, reqlog: reqlog)
            container.fetchState = .succeeded(content: menu, incept: Date())
        } catch {
            _log("> menuFetchStateContainer: -> .failed: \(error)")
            container.fetchState = .failed(error: error)
        }
    }

    // MARK: Internals

    /// If the guest JWT is missing or expires within an one hour, fetch a new one.
    private func _ensureGuestJWT() async throws -> String {
        if let jwt, let exp = jwt.jwtExpDate, exp.timeIntervalSinceNow >= 3600 {
            _log("> _ensureGuestJWT: returning cached JWT")
            return jwt
        } else {
            _log("> _ensureGuestJWT: _getGuestJWT(): start")
            let jwt = try await _getGuestJWT(reqlog: reqlog)
            self.jwt = jwt
            _log("> _ensureGuestJWT: _getGuestJWT(): returning jwt")
            return jwt
        }
    }
}


// MARK: - Stateless low-level HTTP functions


/// Extract the guest JWT from the response headers of www.favordelivery.com.
nonisolated
fileprivate func _getGuestJWT(reqlog: RequestLog? = nil) async throws -> String {
    /*
     Note: we just need to grab a JWT out of the Set-Cookie header, but this is unfortunately
     complicated by Apple's API's.  A fresh fetch of favordelivery.com will return two Set-Cookie
     headers (one for the JWT and one for the session), but iOS exposes headers as a dictionary,
     which means only one entry per header name.
     However, if we use a fresh cookie storage object, Foundation will combine the two Set-Cookie
     headers into a single, comma-separated entry, allowing us to reliably access the JWT.
     */
    let url = URL(string: "https://www.favordelivery.com")!
    let request = URLRequest(url: url)
    let cookieStorage = HTTPCookieStorage()
    let config = URLSessionConfiguration.default
    config.httpCookieAcceptPolicy = .always
    config.httpCookieStorage = cookieStorage
    config.requestCachePolicy = .reloadIgnoringLocalCacheData
    let session = URLSession(configuration: config)

    let (data, response) = try await httpAsData(request: request, session: session, reqlog: reqlog)
    guard let cookie = response.value(forHTTPHeaderField: "Set-Cookie") else {
        _log("_getGuestJWT(): error: no set-cookie")
        throw URLError(.badServerResponse, userInfo: ["data": data, "response": response])
    }
    let regex = /token=(.*?);/
    guard let match = cookie.firstMatch(of: regex) else {
        _log("_getGuestJWT(): error: no token=")
        throw URLError(.badServerResponse, userInfo: ["data": data, "response": response])
    }
    let token = String(match.1)
    _log("_getGuestJWT(): jwt: \(token)")
    return token
}


/// Construct a JWT-authenticated Favor API request.
fileprivate func _makeAPIRequest(
    baseURL: URL,
    path: String,
    jwt: String
) throws -> URLRequest {
    guard let url = URL(string: path, relativeTo: baseURL) else {
        throw URLError(.badURL, userInfo: ["baseURL": baseURL, "path": path])
    }
    var request = URLRequest(url: url)
    request.setValue("JWT \(jwt)", forHTTPHeaderField: "Authorization")
    let agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)"
        + " AppleWebKit/537.36 (KHTML, like Gecko)"
        + " Chrome/143.0.0.0"
        + " Safari/537.36"
    request.setValue(agent, forHTTPHeaderField: "User-Agent")
    // It appears this header isn't required:
//    request.setValue("Favor consumer web 4304", forHTTPHeaderField: "x-favor-user-agent")
    return request
}


/// The 'browse' endpoint returns categories (e.g. "Pizza"), filters, and sections ("For you").
fileprivate func _getBrowse(
    baseURL: URL,
    jwt: String,
    location: GeoLocation,
    reqlog: RequestLog? = nil
) async throws -> (BrowseJSON, HTTPURLResponse) {
    let path = "/page-layouts/v2/browse"
        + "?lat=\(location.latitude)&lng=\(location.longitude)"
    let request = try _makeAPIRequest(baseURL: baseURL, path: path, jwt: jwt)
    return try await httpAsObject(request: request, decodeAs: BrowseJSON.self, reqlog: reqlog)
}


/// The 'merchant' endpoint returns details about a restaurant (e.g. address), but not the menu.
fileprivate func _getMerchant(
    baseURL: URL,
    jwt: String,
    location: GeoLocation,
    merchantID: Int,
    reqlog: RequestLog? = nil
) async throws -> (MerchantJSON, HTTPURLResponse) {
    let path = "/api/v6/merchants/\(merchantID)"
        + "?latitude=\(location.latitude)&longitude=\(location.longitude)"
    let request = try _makeAPIRequest(baseURL: baseURL, path: path, jwt: jwt)
    nonisolated struct ResponseJSON: Decodable, Equatable {
        let merchant: MerchantJSON
    }
    let (obj, response) = try await httpAsObject(request: request, decodeAs: ResponseJSON.self, reqlog: reqlog)
    return (obj.merchant, response)
}


/// The menu URL endpoint returns the path fragment needed to construct the menu URL for a restaurant.
fileprivate func _getMenuURL(
    baseURL: URL,
    jwt: String,
    id: Int,
    reqlog: RequestLog? = nil
) async throws -> (MenuURLJSON, HTTPURLResponse) {
    let path = "/menu-hydration/public/v2/locations/\(id)/menu_url"
        + "?publication_type=PUBLISHED"
    let request = try _makeAPIRequest(baseURL: baseURL, path: path, jwt: jwt)
    return try await httpAsObject(request: request, decodeAs: MenuURLJSON.self, reqlog: reqlog)
}


/// Returns the full menu details.
fileprivate func _getMenuOverview(
    baseURL: URL,
    jwt: String,
    subpath: String,
    reqlog: RequestLog? = nil
) async throws -> (MenuOverviewJSON, HTTPURLResponse) {
    let limit = 100
    let path = "/menu-hydration/public/v2/\(subpath)/overview"
        + "?section_item_limit=\(limit)"
    let request = try _makeAPIRequest(baseURL: baseURL, path: path, jwt: jwt)
    return try await httpAsObject(request: request, decodeAs: MenuOverviewJSON.self, reqlog: reqlog)
}


/// Returns a "category" (e.g. "pizza", "burgers")
fileprivate func _getCategory(
    baseURL: URL,
    jwt: String,
    location: GeoLocation,
    id: String,
    reqlog: RequestLog? = nil
) async throws -> (CategoryJSON, HTTPURLResponse) {
    let page = 1
    let pageSize = 100
    // FIXME: what is "v"?  It appears it isn't required.
//    let v = 1768701747887
//    let path = "/page-layouts/v2/filters/collection"
//        + "?page=\(page)&page_size=\(pageSize)&cuisine=\(id)&lat=\(location.latitude)&lng=\(location.longitude)&v=\(v)"
    let path = "/page-layouts/v2/filters/collection"
        + "?page=\(page)&page_size=\(pageSize)"
        + "&cuisine=\(id)"
        + "&lat=\(location.latitude)&lng=\(location.longitude)"
    let request = try _makeAPIRequest(baseURL: baseURL, path: path, jwt: jwt)
    return try await httpAsObject(request: request, decodeAs: CategoryJSON.self, reqlog: reqlog)
}
