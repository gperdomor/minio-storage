//
//  MinioAdapter.swift
//  MinioStorage
//
//  Created by Gustavo Perdomo on 5/3/18.
//  Copyright © 2018 Gustavo Perdomo. All rights reserved.
//

import AEXML
import Foundation
import SimpleStorageSigner
import Vapor

extension Dictionary {
    init<S: Sequence>(_ s: S) where Element == S.Iterator.Element {
        self.init()
        var iterator = s.makeIterator()
        while let element: Element = iterator.next() {
            self[element.0] = element.1
        }
    }
}

extension Date {
    init(string: String) {
        if string == "" {
            self = Date()
            return
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'hh:mm:ss.zzzZ"
        self = formatter.date(from: string) ?? Date()
    }
}

extension AdapterIdentifier {
    /// The main Minio adapter identifier.
    public static var minio: AdapterIdentifier<MinioAdapter> {
        return .init("minio")
    }
}

/// `MinioAdapter` provides an interface that allows the handeling of files
/// between Minio Private Cloud Storage.
public class MinioAdapter: Adapter {

    /// The region where bucket is located.
    public let region: Region

    /// Minio Access Key
    let accessKey: String

    /// Minio Secret Key
    let secretKey: String

    /// Minio Security Token. Used to validate temporary credentials, such as
    /// those from an EC2 Instance's IAM role
    let securityToken: String?

    /// The Simple Storage Signer to generate the auth headers
    let signer: SimpleStorageSigner!

    let host: URL

    /// Create a new Minio adapter.
    public init(host: URLRepresentable, accessKey: String, secretKey: String, region: Region = .usEast1, securityToken: String? = nil) throws {
        guard let url = host.convertToURL() else {
            throw MinioAdapterError(identifier: "init", reason: "Couldnt not generate a valid URL for '\(host)'", source: .capture())
        }

        guard !url.absoluteString.hasSuffix("s3.amazonaws.com") else {
            throw MinioAdapterError(identifier: "init", reason: "To use AWS S3 please check https://github.com/anthonycastelli/s3-storage", source: .capture())
        }

        self.accessKey = accessKey
        self.secretKey = secretKey
        self.region = region
        self.securityToken = securityToken
        self.host = url
        self.signer = SimpleStorageSigner(accessKey: accessKey, secretKey: secretKey, region: region)
    }
}

extension MinioAdapter {
    internal func getProperURL(bucket: String, object: String) throws -> URL {
        let host = self.region.host(self.host)

        guard let url = URL(string: host + bucket.finished(with: "/") + object) else {
            throw MinioAdapterError(identifier: "getProperURL", reason: "Couldnt not generate a valid URL path.", source: .capture())
        }
        return url
    }

}

/// Handles all of the network requests
extension MinioAdapter {
    public func copy(object: String, from bucket: String, as: String, to targetBucket: String, on container: Container) throws -> EventLoopFuture<ObjectInfo> {
        throw MinioAdapterError(identifier: "copy", reason: "Currently not implemented.", source: .capture())
    }

    public func create(object: String, in bucket: String, with content: Data, metadata: StorageMetadata?, on container: Container) throws -> EventLoopFuture<ObjectInfo> {
        let client = try container.make(Client.self)
        let url = try self.getProperURL(bucket: bucket, object: object)

        // Create any ACL headers we need
        var aclHeaders = [String: String]()
        if let metadata = metadata {
            if let predefinedACL = metadata.predefinedACL?.header {
                if let key = predefinedACL.keys.first, let value = predefinedACL.values.first {
                    aclHeaders[key] = value
                }
            }
        }

        let headers = try self.signer.authHeader(for: .PUT, to: url, headers: aclHeaders, payload: .data(content))
        let request = Request(using: container)
        request.http.method = .PUT
        request.http.headers = headers
        request.http.body = HTTPBody(data: content)
        request.http.url = url

        return try client.respond(to: request).map(to: ObjectInfo.self) { response in
            guard response.http.status == .ok else {
                throw MinioAdapterError(identifier: "create", reason: "Couldnt not create file.", source: .capture())
            }
            return ObjectInfo(name: url.lastPathComponent, prefix: nil, size: nil, etag: "MD5-Hash", lastModified: Date(), url: url)
        }
    }

    public func delete(object: String, in bucket: String, on container: Container) throws -> EventLoopFuture<Void> {
        let client = try container.make(Client.self)
        let url = try self.getProperURL(bucket: bucket, object: object)
        let headers = try self.signer.authHeader(for: .DELETE, to: url, payload: .none)
        let request = Request(using: container)
        request.http.method = .DELETE
        request.http.headers = headers
        request.http.url = url
        return try client.respond(to: request).map(to: Void.self) { response in
            guard response.http.status == .noContent else {
                throw MinioAdapterError(identifier: "delete", reason: "Couldnt not delete the file.", source: .capture())
            }
            return ()
        }
    }

    public func get(object: String, in bucket: String, on container: Container) throws -> EventLoopFuture<Data> {
        let client = try container.make(Client.self)
        let url = try self.getProperURL(bucket: bucket, object: object)
        let headers = try self.signer.authHeader(for: .GET, to: url, payload: .none)
        let request = Request(using: container)
        request.http.method = .GET
        request.http.headers = headers
        request.http.url = url
        return try client.respond(to: request).map(to: Data.self) { response in
            guard let data = response.http.body.data else {
                throw MinioAdapterError(identifier: "get", reason: "Couldnt not extract data from the request.", source: .capture())
            }
            return data
        }
    }

    public func listObjects(in bucket: String, prefix: String?, on container: Container) throws -> EventLoopFuture<[ObjectInfo]> {
        let client = try container.make(Client.self)
        var urlComponents = URLComponents(string: self.region.host)
        urlComponents?.path = "/" + bucket
        urlComponents?.queryItems = []
        urlComponents?.queryItems?.append(URLQueryItem(name: "list-type", value: "2"))
        if let prefix = prefix {
            urlComponents?.queryItems?.append(URLQueryItem(name: "prefix", value: prefix))
        }
        guard let url = urlComponents?.url else {
            throw MinioAdapterError(identifier: "list", reason: "Couldnt not generate a valid URL path.", source: .capture())
        }

        let headers = try self.signer.authHeader(for: .GET, to: url, payload: .none)
        let request = Request(using: container)
        request.http.method = .GET
        request.http.headers = headers
        request.http.url = url

        return try client.respond(to: request).map(to: [ObjectInfo].self) { response in
            guard response.http.status == .ok else {
                throw MinioAdapterError(identifier: "list", reason: "Error: \(response.http.status.reasonPhrase). There requested returned a \(response.http.status.code)", source: .capture())
            }
            guard let data = response.http.body.data else {
                throw MinioAdapterError(identifier: "list", reason: "Couldnt not extract the data from the request.", source: .capture())
            }
            let xml = try AEXMLDocument(xml: data)
            let items = xml.root.allDescendants(where: { $0.name == "Contents" }).map({ Dictionary($0.children.compactMap({ [$0.name: $0.value ?? ""] }).reduce([], { $0 + $1 })) })
            return items.map({
                ObjectInfo(
                    name: $0["Key"] ?? "",
                    prefix: $0["Prefix"],
                    size: Int($0["Size"] ?? "0"),
                    etag: $0["ETag"] ?? "",
                    lastModified: Date(string: $0["LastModified"] ?? ""),
                    url: URL(string: self.region.host + bucket.finished(with: "/") + ($0["Key"] ?? ""))
                )
            })
        }
    }
}

extension MinioAdapter {
    public func create(bucket: String, metadata: StorageMetadata?, on container: Container) throws -> EventLoopFuture<Void> {
        fatalError("Not implemented")
    }

    public func delete(bucket: String, on container: Container) throws -> EventLoopFuture<Void> {
        fatalError("Not implemented")
    }

    public func get(bucket: String, on container: Container) throws -> EventLoopFuture<BucketInfo?> {
        fatalError("Not implemented")
    }

    public func list(on container: Container) throws -> EventLoopFuture<[BucketInfo]> {
        fatalError("Not implemented")
    }
}
