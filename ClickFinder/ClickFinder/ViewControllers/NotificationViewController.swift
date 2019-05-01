//
//  NotificationViewController.swift
//  clickFinder
//
//  Created by Ivan Pavic (ivan.pavic@student.supsi.ch) and Patrick Valnegri(patrick.valnegri@student.supsi.ch) on 26.04.19.
//  Copyright © 2019 Ray Wenderlich. All rights reserved.
//

import Foundation
import UIKit
import WebKit
import CoreData

class NotificationViewController: UIViewController, WKNavigationDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var beaconPhoto: UIImageView!
    @IBOutlet weak var phoneBtn: UIButton!
    
    //delegate of AppDelegate
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    //notification url
    var urlString: String = ""
    
    //beacon lost
    var urlParam: String = ""
    
    //antenna phone
    var urlAntennaPhone: String = ""
    
    //antenna name
    var urlAntennaName: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //If antenna phone is null or antenna name is utente or empty button call is not visible
        if (urlAntennaPhone == "null"  || urlAntennaName == "utente" || urlAntennaName == "") {
            phoneBtn.isHidden = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        loadPage()
        loadImage()
    }
    
    @IBAction func returnToHome(_ sender: Any) {
        dismiss(animated: true, completion: nil)
        let VC1 = self.storyboard!.instantiateViewController(withIdentifier: "mainView") as! MainViewController
        let navController = UINavigationController(rootViewController: VC1)
        
        self.present(navController, animated:true, completion: nil)
        
    }
    
    @IBAction func callBtn_tapped(_ sender: Any) {
        guard let number = URL(string: "tel://\(urlAntennaPhone)") else { return }
        UIApplication.shared.open(number)
    }
    
    func loadPage() {
        //Build the URL recieved from the push notification
        let url : NSString = urlString as NSString
        let urlStr : NSString = url.addingPercentEscapes(using: String.Encoding.utf8.rawValue)! as NSString
        let searchURL : NSURL = NSURL(string: urlStr as String)!
        
        webView.load(URLRequest(url: searchURL as URL))
        
        //reset url
        urlString = ""
    }
    
    func loadImage() {
        let paramArr = urlParam.components(separatedBy: "_")
        
        let major = Int(paramArr[1])
        let minor = Int(paramArr[2])
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Items")
        let context = appDelegate.persistentContainer.viewContext
        
        let p1 = NSPredicate(format: "major == %@", major! as NSNumber)
        let p2 = NSPredicate(format: "minor == %@", minor! as NSNumber)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [p1, p2])
        
        //Get the photo of the given major and minor values recieved from the push notification from CoreData
        request.predicate = predicate
        do {
            let result = try context.fetch(request)
            for data in result as! [NSManagedObject] {
                let imageData = Data(base64Encoded: data.value(forKey: "photo") as! String, options: Data.Base64DecodingOptions.ignoreUnknownCharacters)!
                let decodedImage = UIImage(data: imageData)!
                
                //Load image in view
                beaconPhoto.image = decodedImage
            }
        } catch {
            print("Failed")
        }
    }
}

