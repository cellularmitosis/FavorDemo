//
//  HTTP.swift
//  FavorAPI
//
//  Created by Jason Pepas on 1/16/26.
//

import Foundation

fileprivate nonisolated let dumpURL: Bool = true
fileprivate nonisolated let dumpJSON: Bool = false
fileprivate nonisolated let logJSONToTmp: Bool = true
fileprivate nonisolated let dumpCurl: Bool = true


nonisolated
struct NotImplemented: Error {}

nonisolated
enum HTTPError: Error {
    case notHTTP(response: URLResponse, data: Data)
    case badStatusCode(response: HTTPURLResponse, data: Data)
    case cantDecodeAsUTF8String(response: HTTPURLResponse, data: Data)
}


/// Perform an HTTP request and return Data.
nonisolated
func httpAsData(
    request: URLRequest,
    session: URLSession = .shared,
    reqlog: RequestLog? = nil
) async throws -> (Data, HTTPURLResponse) {
    if dumpURL {
        print("> httpAsData(): URL: \(String(describing: request.url))")
    }
    if dumpCurl {
        print()
        if let auth = request.value(forHTTPHeaderField: "Authorization") {
            print("> httpAsData(): curl '\(request.url!)' -H 'Authorization: \(auth)'")
        } else {
            print("> httpAsData(): curl '\(request.url!)'")
        }
    }

    let then = Date()
    let (data, response) = try await session.data(for: request)
    let now = Date()
    let elapsed = now.timeIntervalSince(then)
    Task { @MainActor in
        let entry = RequestLogEntry(elapsed: elapsed, request: request, response: response)
        reqlog?.append(entry)
    }

    guard let httpResponse = response as? HTTPURLResponse else {
        throw HTTPError.notHTTP(response: response, data: data)
    }

    guard (200...299).contains(httpResponse.statusCode) else {
        if let text = String(data: data, encoding: .utf8) {
            print("> HTTP \(httpResponse.statusCode): \(text)")
        }
        throw HTTPError.badStatusCode(response: httpResponse, data: data)
    }

    if dumpJSON {
        print("> httpAsData(): JSON: \(String(describing: String(data: data, encoding: .utf8)))")
        print()
    }
    if logJSONToTmp {
        let fname = "\(request.url!.host()!)_\(request.url!.path()).\(httpResponse.statusCode)"
            .replacingOccurrences(of: "/", with: "_")
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fname)
        do {
            try data.write(to: fileURL, options: [.atomic])
            print("> httpAsData(): JSON logged to " + "\(fileURL)".replacingOccurrences(of: "file://", with: ""))
        }
    }
    return (data, httpResponse)
}


/// Perform an HTTP request and return String.
nonisolated
func httpAsString(
    request: URLRequest,
    session: URLSession = .shared,
    encoding: String.Encoding = .utf8,
    reqlog: RequestLog? = nil
) async throws -> (String, HTTPURLResponse) {
    let (data, response) = try await httpAsData(request: request, session: session, reqlog: reqlog)
    guard let str = String(data: data, encoding: encoding) else {
        throw HTTPError.cantDecodeAsUTF8String(response: response, data: data)
    }
    return (str, response)
}


/// Perform an HTTP request and return an object decoded from JSON.
nonisolated
func httpAsObject<T: Decodable&Sendable>(
    request: URLRequest,
    session: URLSession = .shared,
    decodeAs type: T.Type,
    reqlog: RequestLog? = nil
) async throws -> (T, HTTPURLResponse) {
    let (data, response) = try await httpAsData(request: request, session: session, reqlog: reqlog)
    let obj = try await Task {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: data)
    }.value
    return (obj, response)
}
