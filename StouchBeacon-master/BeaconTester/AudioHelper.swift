import UIKit
import AVFoundation

let sharedAudioHelper = AudioHelper()

class AudioHelper: NSObject {
    var audioPlayer: AVAudioPlayer = AVAudioPlayer()
        
    class func sharedInstance() -> AudioHelper {
        return sharedAudioHelper
    }
    
    func playSound(long: Bool) {
        let soundUrl = (long) ? AppConstants.longSound : AppConstants.shortSound
        Logger.log(what: soundUrl)
        playBackgroundMusic(filename: soundUrl)
    }
    
    
    var backgroundMusicPlayer = AVAudioPlayer()
    
    func playBackgroundMusic(filename: String) {
        
        //let url = Bundle.main.url(forResource: filename, withExtension: nil)
        let url = URL(fileURLWithPath: filename)
        
        /*
        guard let newURL = url else {
            print("Could not find file: \(filename)")
            return
        }*/
        do {
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: url)
            backgroundMusicPlayer.numberOfLoops = 1
            backgroundMusicPlayer.prepareToPlay()
            backgroundMusicPlayer.play()
        } catch let error as NSError {
            print(error.description)
        }
    }
}



