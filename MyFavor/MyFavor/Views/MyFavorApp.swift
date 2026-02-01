//
//  MyFavorApp.swift
//  MyFavor
//
//  Created by Jason Pepas on 1/17/26.
//

import SwiftUI


fileprivate var _reqlog = RequestLog()


@main
struct MyFavorApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .environment(FavorClient(location: .momAndDadsHouse, reqlog: _reqlog))
        .environment(FavoriteMerchantsStore())
        .environment(_reqlog)
    }
}
