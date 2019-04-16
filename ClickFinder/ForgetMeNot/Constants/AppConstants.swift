import CoreLocation

import Foundation
import UIKit

struct Colors {
    static let background = UIColor(red: 159/255, green: 168/255, blue: 218/255, alpha: 1)
}

struct Fonts {
    static let font = "AvenirNext-Medium"
}

class AppConstants {
    
    static let uuid = UUID(uuidString: "699EBC80-E1F3-11E3-9A0F-0CF3EE3BC012")!

    //static let uuid = UUID(uuidString: "5A4BCFCE-174E-4BAC-A814-092E77F6B7E5")!
    static let region = CLBeaconRegion(proximityUUID: uuid, identifier: uuid.uuidString)
    
    static var mainPageURL = URL(string: "https://www.ticinonews.ch/")
    
    static let publicKeyServer = "APA91bEeQpKqoHlK9aWR57A_J7q-StE87xOUwLMBCjXyEklqFOw5Q2MJ6EBjq-oVo8uff8KziQymiAfJ_4IGBA2W0-9d4VS2N8clgQGJozPNLRkIcYK-wds1OuEbpUQ3Qy0UFgoPrA9O"
    static let privateKeyServer = "AAAAOQ9a1kc:APA91bFU3g7xfVMLAO7FOQepL1jLQnWqUZ0cU77efNoYoW5eIMiVDVidPOqswqlGetQZjVsq-FGpWDpo_VRtI2mFn4hrt6jp9opDRAa8mfZjrHqzw8SOTYxeXA9VB13xdH-y_8oRUp2jHOF2Az1BTOV6Z-BHjrbJkQ"
    static let comandCheckAlarm = "CHECK_ALARM"
    
    static var userName: String = ""
    static var userPhone: String = ""
    
    static var pairingValue = 39168
}
