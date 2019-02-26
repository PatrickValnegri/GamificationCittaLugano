import AVFoundation

class AppConstants {
    static let uuid       = NSUUID(uuidString: "699EBC80-E1F3-11E3-9A0F-0CF3EE3BC012")
    static let mainUri    = "https://www.luganolac.ch/it/3/eventi"
    static let pairUri    = "http://www.tv-surf.com/stouch/pairing.html"
    static let pairedUri  = "http://www.tv-surf.com/stouch/paired_lac.html"
    
    static let checkUserDet = "http://www.tv-surf.com/3D-Enter/servlet/P13_19_CommandXML?idUser=XXX&comando=CHECK_USER_DET"
    static let checkAlarm   = "http://www.tv-surf.com/3D-Enter/servlet/P13_19_CommandXML?comando=CHECK_ALARM"
    static let setHdd       = "http://www.tv-surf.com/3D-Enter/servlet/P13_19_CommandXML?comando=SET_HDD"
    
    
    static let longSound = "/Library/Ringtones/Opening.m4r"
    static let shortSound  = "/System/Library/Audio/UISounds/sms-received1.caf"
}
