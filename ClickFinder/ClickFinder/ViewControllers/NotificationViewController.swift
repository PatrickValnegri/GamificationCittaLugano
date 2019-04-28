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

class NotificationViewController: UIViewController, WKNavigationDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var webView: WKWebView!
    
    var urlString: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        loadPage()
    }
    
    func loadPage() {
        print("URL Notifica: ", urlString)

        let url : NSString = urlString as NSString
        let urlStr : NSString = url.addingPercentEscapes(using: String.Encoding.utf8.rawValue)! as NSString
        let searchURL : NSURL = NSURL(string: urlStr as String)!
        print(searchURL)
        
        print("Pagina ricaricata")
        webView.load(URLRequest(url: searchURL as URL))
    }
    
    @IBAction func returnToHome(_ sender: Any) {
        
        dismiss(animated: true, completion: nil)
        let VC1 = self.storyboard!.instantiateViewController(withIdentifier: "mainView") as! MainViewController
        let navController = UINavigationController(rootViewController: VC1) // Creating a navigation controller with VC1 at the root of the navigation stack.
        self.present(navController, animated:true, completion: nil)
        
    }
    
}

