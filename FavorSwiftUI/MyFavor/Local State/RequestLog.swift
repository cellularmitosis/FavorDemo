//
//  RequestLog.swift
//  MyFavor
//
//  Created by Jason Pepas on 2/1/26.
//

import Foundation
import Observation


// MARK: - RequestLogEntry

struct RequestLogEntry: Identifiable {
    let id = UUID()
    let elapsed: TimeInterval
    let request: URLRequest
    let response: URLResponse
}


// MARK: - RequestLog

@Observable
class RequestLog {
    private(set) var entries: [RequestLogEntry] = []

    func append(_ entry: RequestLogEntry) {
        entries.append(entry)
    }
}
