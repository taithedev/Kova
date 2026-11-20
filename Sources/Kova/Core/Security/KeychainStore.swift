import Foundation
import Security
struct KeychainStore {
    private static let service="com.zuzify.kova.session"
    static func write(_ token:String) {
        remove()
        let data=Data(token.utf8)
        let query:[String:Any] = [kSecClass as String:kSecClassGenericPassword,kSecAttrService as String:service,kSecAttrAccount as String:"auth",kSecValueData as String:data,kSecAttrAccessible as String:kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]
        SecItemAdd(query as CFDictionary,nil)
    }
    static func read()->String? {
        let query:[String:Any] = [kSecClass as String:kSecClassGenericPassword,kSecAttrService as String:service,kSecAttrAccount as String:"auth",kSecReturnData as String:true,kSecMatchLimit as String:kSecMatchLimitOne]
        var result:CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary,&result)==errSecSuccess, let data=result as? Data else { return nil }
        return String(data:data,encoding:.utf8)
    }
    static func remove() {
        let query:[String:Any] = [kSecClass as String:kSecClassGenericPassword,kSecAttrService as String:service,kSecAttrAccount as String:"auth"]
        SecItemDelete(query as CFDictionary)
    }
}
