//
//  JSONDecoder.swift
//  Honeycomb
//
//  Created by Chris Li on 12/9/23.
//

import Foundation

class PhotoPrismJSONDecoder: JSONDecoder {
    override init() {
        super.init()
        dateDecodingStrategy = .iso8601
        keyDecodingStrategy = .custom { keys -> CodingKey in
            guard let key = keys.last else { return ResponseDataKey(stringValue: "") }
            if let intValue = key.intValue {
                return ResponseDataKey(intValue: intValue)
            } else if key.stringValue == "UID" {
                return ResponseDataKey(stringValue: "uid")
            } else {
                let stringValue = key.stringValue.prefix(1).lowercased() + key.stringValue.dropFirst()
                return ResponseDataKey(stringValue: stringValue)
            }
        }
    }
    
    struct ResponseDataKey: CodingKey {
        var stringValue: String
        var intValue: Int?
        
        init(stringValue: String) {
            self.stringValue = stringValue
            self.intValue = nil
        }
        
        init(intValue: Int) {
            self.stringValue = String(intValue)
            self.intValue = intValue
        }
    }
}
