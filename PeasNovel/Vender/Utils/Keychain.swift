/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 A struct for accessing generic password keychain items.
 */

import Foundation




struct Keychain {
    // MARK: Types
    
    enum KeychainError: Error {
        case noPassword
        case unexpectedPasswordData
        case unexpectedItemData
        case unhandledError(status: OSStatus)
    }
    
    struct Configuration {
        
        static let serviceName = "com.notbroken.service"
        static let deviceId = "deviceID"
        static let accessGroup: String? = nil
    }
    
    // MARK: Properties
    
    let service: String
    
    private var key: String
//    private(set) var identifier: String
    
    let accessGroup: String?
    
    // MARK: Intialization
    
    init(service: String, accessGroup: String? = nil) {
        self.service = service
        self.key = Keychain.Configuration.deviceId
        self.accessGroup = accessGroup
    }
    
    // MARK: Keychain access
    
    func read() throws -> String  {
        /*
         Build a query to find the item that matches the service, account and
         access group.
         */
        var query = Keychain.keychainQuery(withService: service, identifier: key, accessGroup: accessGroup)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecReturnData as String] = kCFBooleanTrue
        
        // Try to fetch the existing keychain item that matches the query.
        var queryResult: AnyObject?
        let status = withUnsafeMutablePointer(to: &queryResult) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        
        // Check the return status and throw an error if appropriate.
        guard status != errSecItemNotFound else { throw KeychainError.noPassword }
        guard status == noErr else { throw KeychainError.unhandledError(status: status) }
        
        // Parse the password string from the query result.
        guard let existingItem = queryResult as? [String : AnyObject],
//            let passwordData = existingItem[kSecValueData as String] as? Data,
            let key = existingItem[kSecValueData as String] as? Data,
            let identifier = String(data: key, encoding: String.Encoding.utf8)
            else {
                throw KeychainError.unexpectedPasswordData
        }
        
        return identifier
    }
    
    func save(_ ide: String?) throws {

        guard let ide = ide else { throw KeychainError.unexpectedPasswordData }
        let deviceId = ide.data(using: String.Encoding.utf8)!
        do {
            // Check for an existing item in the keychain.
            try _ = read()
            
            // Update the existing item with the new password.
            var attributesToUpdate = [String : AnyObject]()
            attributesToUpdate[kSecValueData as String] = deviceId as AnyObject
            let query = Keychain.keychainQuery(withService: service, identifier: key, accessGroup: accessGroup)
            let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
            
            // Throw an error if an unexpected status was returned.
            guard status == noErr else { throw KeychainError.unhandledError(status: status) }
        }
        catch KeychainError.noPassword {
            /*
             No password was found in the keychain. Create a dictionary to save
             as a new keychain item.
             */
            var newItem = Keychain.keychainQuery(withService: service, identifier: key, accessGroup: accessGroup)
            newItem[kSecValueData as String] = deviceId as AnyObject?
            
            // Add a the new item to the keychain.
            let status = SecItemAdd(newItem as CFDictionary, nil)
            
            // Throw an error if an unexpected status was returned.
            guard status == noErr else { throw KeychainError.unhandledError(status: status) }
        }
    }
    
    func deleteItem() throws {
        // Delete the existing item from the keychain.
        let query = Keychain.keychainQuery(withService: service, identifier: key, accessGroup: accessGroup)
        let status = SecItemDelete(query as CFDictionary)
        
        // Throw an error if an unexpected status was returned.
        guard status == noErr || status == errSecItemNotFound else { throw KeychainError.unhandledError(status: status) }
    }
    
    static func items(forService service: String, accessGroup: String? = nil) throws -> [Keychain] {
        // Build a query for all items that match the service and access group.
        var query = Keychain.keychainQuery(withService: service, accessGroup: accessGroup)
        query[kSecMatchLimit as String] = kSecMatchLimitAll
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecReturnData as String] = kCFBooleanFalse
        
        // Fetch matching items from the keychain.
        var queryResult: AnyObject?
        let status = withUnsafeMutablePointer(to: &queryResult) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        
        // If no items were found, return an empty array.
        guard status != errSecItemNotFound else { return [] }
        
        // Throw an error if an unexpected status was returned.
        guard status == noErr else { throw KeychainError.unhandledError(status: status) }
        
        // Cast the query result to an array of dictionaries.
        guard let resultData = queryResult as? [[String : AnyObject]] else { throw KeychainError.unexpectedItemData }
        
        // Create a `KeychainPasswordItem` for each dictionary in the query result.
        var passwordItems = [Keychain]()
        for result in resultData {
            guard let account  = result[kSecAttrLabel as String] as? String else { throw KeychainError.unexpectedItemData }
            print(account)
            let passwordItem = Keychain(service: service, accessGroup: accessGroup)
            passwordItems.append(passwordItem)
        }
        
        return passwordItems
    }
    
    // MARK: Convenience
    
    private static func keychainQuery(withService service: String, identifier: String? = nil, accessGroup: String? = nil) -> [String : AnyObject] {
        var query = [String : AnyObject]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = service as AnyObject?
        
        if let identifier = identifier {
            query[kSecAttrAccount as String] = identifier as AnyObject?
        }
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup as AnyObject?
        }
        
        return query
    }
}
