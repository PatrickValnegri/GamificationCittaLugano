import CoreLocation

class AppConstants {
    static let uuid = UUID(uuidString: "5A4BCFCE-174E-4BAC-A814-092E77F6B7E5")!
    static let region = CLBeaconRegion(proximityUUID: uuid, identifier: "Pairing")
}
