//
//  JWT.swift
//  MyFavor
//
//  Created by Jason Pepas on 1/17/26.
//

import Foundation


// Note: these JWT-related extenions are derived from a function by ChatGPT.

extension String {
    /// The "payload" is the part between the two dots of a JWT.
    var jwtPayload: String? {
        let parts = self.split(separator: ".")
        guard let payload = parts.get(at: 1) else {
            return nil
        }
        return String(payload)
    }

    var base64URLDecoded: Data? {
        var base64 = self
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder != 0 {
            let suffix = String(repeating: "=", count: remainder)
            base64 += suffix
        }
        return Data(base64Encoded: base64)
    }

    var asJWTPayloadDict: [String:Any]? {
        guard let data = self.jwtPayload?.base64URLDecoded else {
            return nil
        }
        guard let dict = try? JSONSerialization.jsonObject(with: data) as? [String:Any] else {
            return nil
        }
        return dict
    }

    var jwtExpDate: Date? {
        return self.asJWTPayloadDict?.jwtValueAsDate(key: "exp")
    }
}


fileprivate extension [String:Any] {
    func jwtValueAsDate(key: String) -> Date? {
        guard let exp = self[key] as? Int else {
            return nil
        }
        return Date(timeIntervalSince1970: Double(exp))
    }
}
