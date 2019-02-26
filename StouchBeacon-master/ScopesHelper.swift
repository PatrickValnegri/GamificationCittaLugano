import Foundation

import PermissionScope

class ScopesHelper {
    static func displayScope() -> Bool {
        var display = false
    
        switch PermissionScope().statusNotifications() {
            case .unknown:
                display = true
                break
            case .disabled:
                display = true
                break
            default:
            break
        }
        
        switch PermissionScope().statusLocationAlways() {
            case .unknown:
                display = true
                break
            case .disabled:
                display = true
                break
            default:
                break
        }
        
        return display
    }
}
