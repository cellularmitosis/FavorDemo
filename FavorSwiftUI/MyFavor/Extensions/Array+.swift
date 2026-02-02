//
//  Array+.swift
//  MyFavor
//
//  Created by Jason Pepas on 1/17/26.
//

import Foundation


extension Array {
    /// Safe array access.
    func get(at index: Int) -> Element? {
        guard index < self.count else {
            return nil
        }
        return self[index]
    }
}
