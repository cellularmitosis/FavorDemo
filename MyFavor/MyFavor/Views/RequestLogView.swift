//
//  RequestLogView.swift
//  MyFavor
//
//  Created by Jason Pepas on 1/23/26.
//

import SwiftUI


// MARK: - RequestLogView

/// The developer menu HTTP request log.
struct RequestLogView: View {
    var body: some View {
        List {
            ForEach(_reqlog.entries) { entry in
                ReqLogCell(entry: entry)
            }
        }
        .navigationTitle("Request Log")
    }

    @Environment(RequestLog.self) private var _reqlog
}


// MARK: - ReqLogCell

struct ReqLogCell: View {
    let entry: RequestLogEntry

    var body: some View {
        VStack(alignment: .leading) {
            Text("Host: \(entry.request.url?.host() ?? "(nil)")")
            Text("Path: \(entry.request.url?.path() ?? "(nil)")")
            Text("Method: \(entry.request.httpMethod ?? "(nil)") | status: \(_statusCode)")
            Text("Latency: \(_latency)")
        }
        .listRowBackground(_colorStore.color(entry: entry, scheme: _colorScheme))
    }

    // MARK: Internals

    @Environment(\.colorScheme) private var _colorScheme

    private var _statusCode: String {
        guard let code = (entry.response as? HTTPURLResponse)?.statusCode else {
            return "(nil)"
        }
        if (200...299).contains(code) {
            return "\(code) ✅"
        } else {
            return "\(code) ⚠️"
        }
    }

    private var _latency: String {
        let elapsed = "\(Int(entry.elapsed * 1000))ms"
        if entry.elapsed > 1.0 {
            return "\(elapsed) 🐢🐢"
        } else if entry.elapsed > 0.5 {
            return "\(elapsed) 🐢"
        } else {
            return "\(elapsed) 🐇"
        }
    }

    private var _urlEmoji: String {
        let key = "\(entry.request.httpMethod ?? "(nil)") \(entry.request.url?.absoluteString ?? "(nil)")"
        return key.hashValue.asEmoji
    }
}


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


// MARK: - _ReqLogColorStore

fileprivate class _ReqLogColorStore {
    func color(entry: RequestLogEntry, scheme: ColorScheme) -> Color {
        let key = "\(entry.request.httpMethod ?? "(nil)") \(entry.request.url?.absoluteString ?? "(nil)") \(scheme)"
        if let color = _cache[key] {
            return color
        } else {
            let color = Color.randomBackground(respectingColorScheme: scheme)
            _cache[key] = color
            return color
        }
    }

    private var _cache: [String: Color] = [:]
}

fileprivate let _colorStore = _ReqLogColorStore()
