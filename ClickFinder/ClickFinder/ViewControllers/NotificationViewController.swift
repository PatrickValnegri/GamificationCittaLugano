//
//  NotificationViewController.swift
//  clickFinder
//
//  Created by Patrick on 26.04.19.
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
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate //delegate of AppDelegate
    
    var urlString: String = ""
    var urlParam: String = ""
    var urlAntennaPhone: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (urlAntennaPhone == "null") {
            phoneBtn.isHidden = true
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        //carica url notifica
        loadPage()
        
        //carica immagine beacon perso nella notifica
        loadImage()
    }
    
    func loadPage() {
        //print("URL Notifica: ", urlString)

        //Build url notifica
        let url : NSString = urlString as NSString
        let urlStr : NSString = url.addingPercentEscapes(using: String.Encoding.utf8.rawValue)! as NSString
        let searchURL : NSURL = NSURL(string: urlStr as String)!
        
        webView.load(URLRequest(url: searchURL as URL))
        
        //reset url
        urlString = ""
    }
    
    func loadImage() {
        let paramArr = urlParam.components(separatedBy: "_")
        
        //let uuid = Int(paramArr[0])
        let major = Int(paramArr[1])
        let minor = Int(paramArr[2])
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Items")
        let context = appDelegate.persistentContainer.viewContext
        
        let p1 = NSPredicate(format: "major == %@", major! as NSNumber)
        let p2 = NSPredicate(format: "minor == %@", minor! as NSNumber)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [p1, p2])
        
        //Cerco in coredata l'immagine con il valore di major e minor ricevuto dalla notifica
        request.predicate = predicate
        do {
            let result = try context.fetch(request)
            for data in result as! [NSManagedObject] {
                //print("DATO: ",data.value(forKey: "name") as! String)
                let imageData = Data(base64Encoded: data.value(forKey: "photo") as! String, options: Data.Base64DecodingOptions.ignoreUnknownCharacters)!
                let decodedImage = UIImage(data: imageData)!
                
                //carico immagine nella view
                beaconPhoto.image = decodedImage
            }
            
        } catch {
            
            print("Failed")
        }
    }
    
    @IBAction func returnToHome(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
        let VC1 = self.storyboard!.instantiateViewController(withIdentifier: "mainView") as! MainViewController
        let navController = UINavigationController(rootViewController: VC1) // Creating a navigation controller with VC1 at the root of the navigation stack.
        self.present(navController, animated:true, completion: nil)
        
    }
    
    @IBAction func callBtn_tapped(_ sender: Any) {
        guard let number = URL(string: "tel://\(urlAntennaPhone)") else { return }
        UIApplication.shared.open(number)
    }
    
}

