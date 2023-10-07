//
//  DataSource.swift
//  Honeycomb
//
//  Created by Chris Li on 10/1/23.
//

import Foundation

class DataSource {
    let urlSession: URLSession
    let apiRoot: URL?
    
    init() {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["X-Session-ID": UserDefaults.standard.string(forKey: "SessionID") ?? ""]
        urlSession = URLSession(configuration: config)
        apiRoot = URL(string: UserDefaults.standard.string(forKey: "ServerURL") ?? "")?.appending(path: "api/v1")
    }
    
    enum Error: Swift.Error {
        case url
        case unauthorized
    }
    
    func get<T>(path: String? = nil, queryItems: [URLQueryItem] = []) async throws -> T where T: Decodable {
        // assemble URL
        guard var url = apiRoot else { throw Error.url }
        if let path {
            url.append(path: path)
        }
        url.append(queryItems: queryItems)
        print(url)
        
        // get data
        let (data, response) = try await urlSession.data(from: url)
        if let response = response as? HTTPURLResponse, response.statusCode == 401 {
            throw Error.unauthorized
        }
        
        // decode data
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .custom { keys -> CodingKey in
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
        return try decoder.decode(T.self, from: data)
    }
    
    static func makeImageURL(hash: String, suffix: ImageURLSuffix) -> URL? {
        guard var url = URL(string: UserDefaults.standard.string(forKey: "ServerURL") ?? "") else { return nil }
        url.append(path: "api/v1/t")
        url.append(path: hash)
        url.append(path: UserDefaults.standard.string(forKey: "PreviewToken") ?? "")
        url.append(path: suffix.rawValue)
        return url
    }
    
    static func makeVideoURL(hash: String, suffix: String) -> URL? {
        guard var url = URL(string: UserDefaults.standard.string(forKey: "ServerURL") ?? "") else { return nil }
        url.append(path: "api/v1/videos")
        url.append(path: hash)
        url.append(path: UserDefaults.standard.string(forKey: "PreviewToken") ?? "")
        url.append(path: suffix)
        return url
    }
}

private struct ResponseDataKey: CodingKey {
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
