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
        
        loadPage()
    }
    
    func loadPage() {
        print("URL Notifica: ", urlString)
        //let url = URL(string: "https://www.google.com/")!
        //let url = URL(string: urlString)!
        //let url = AppConstants.mainPageURL!
        
        let url : NSString = urlString as NSString
        let urlStr : NSString = url.addingPercentEscapes(using: String.Encoding.utf8.rawValue)! as NSString
        let searchURL : NSURL = NSURL(string: urlStr as String)!
        print(searchURL)
        
        
        webView.load(URLRequest(url: searchURL as URL))
    }
    
}

