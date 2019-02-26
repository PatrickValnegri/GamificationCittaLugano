import AVFoundation

class Logger {
    private static let dateFormatter = DateFormatter()
    
    static func log(what: String){
        dateFormatter.dateFormat = "M/d/yy, H:mm:ss"
        print(dateFormatter.string(from: NSDate() as Date) + " " + what)
    }
    
}
