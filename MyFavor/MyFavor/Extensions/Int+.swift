//
//  Int+.swift
//  MyFavor
//
//  Created by Jason Pepas on 1/23/26.
//

extension Int {
    // This is an abbreviated version of something I wrote years ago, see https://gist.github.com/cellularmitosis/d425aae5f1a2e5d9bfa1d4c1a5968d22
    var asEmoji: String {
        let range = 0x1F300...0x1F3F0
        let index = self % range.count
        let ord = range.lowerBound + index
        guard let scalar = UnicodeScalar(ord) else {
            return "❓"
        }
        return String(scalar)
    }
}
