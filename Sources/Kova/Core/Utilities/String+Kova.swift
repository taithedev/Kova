import Foundation
extension String {
    var trimmed:String {trimmingCharacters(in:.whitespacesAndNewlines)}
    var isValidHandle:Bool {range(of:"^[a-z0-9_]{3,25}$",options:.regularExpression) != nil}
}
