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
    static let uuid = UUID(uuidString: "5A4BCFCE-174E-4BAC-A814-092E77F6B7E5")!
    static let region = CLBeaconRegion(proximityUUID: uuid, identifier: uuid.uuidString)
}
