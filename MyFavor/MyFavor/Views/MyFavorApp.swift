//
//  MyFavorApp.swift
//  MyFavor
//
//  Created by Jason Pepas on 1/17/26.
//

import SwiftUI


@main
struct MyFavorApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .environment(FavorClient(location: .momAndDadsHouse))
        .environment(FavoriteMerchantsStore())
        .environment(g_reqlog)
    }
}


// MARK: Globals

var g_reqlog = RequestLog()
