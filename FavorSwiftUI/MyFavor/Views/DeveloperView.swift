//
//  DeveloperView.swift
//  MyFavor
//
//  Created by Jason Pepas on 1/23/26.
//

import SwiftUI


struct DeveloperView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Request Log", destination: RequestLogView())
            }
            .navigationTitle("Developer")
        }
    }
}
