//
//  Color+.swift
//  MyFavor
//
//  Created by Jason Pepas on 1/23/26.
//

import SwiftUI


extension Color {
    static func random() -> Color {
        return .init(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }

    static func randomBackground(respectingColorScheme scheme: ColorScheme) -> Color {
        switch scheme {
        case .light:
            return .init(
                red: .random(in: 0.6...1),
                green: .random(in: 0.6...1),
                blue: .random(in: 0.6...1)
            )
        case .dark:
            return .init(
                red: .random(in: 0...0.6),
                green: .random(in: 0...0.6),
                blue: .random(in: 0...0.6)
            )
        default:
            return Color.random()
        }
    }
}
