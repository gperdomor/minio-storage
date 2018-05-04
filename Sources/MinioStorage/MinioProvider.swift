//
//  MinioProvider.swift
//  MinioStorage
//
//  Created by Gustavo Perdomo on 5/3/18.
//  Copyright © 2018 Gustavo Perdomo. All rights reserved.
//

import Foundation
import Service

/// Registers and boots Local Adapter services.
public final class MinioStorageProvider: Provider {
    /// See Provider.repositoryName
    public static let repositoryName = "storage-minio"

    /// Create a new Local provider.
    public init() { }

    /// See Provider.register
    public func register(_ services: inout Services) throws {
        try services.register(StorageKitProvider())
    }

    /// See Provider.boot
    public func didBoot(_ container: Container) throws -> Future<Void> {
        return .done(on: container)
    }
}
