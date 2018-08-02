//
//  EvergentGatewayAppDelegate.swift
//  gateway
//
//  Created by Aminul Hasan on 5/30/18.
//  Copyright © 2018 Evergent. All rights reserved.
//

import Foundation
import FBSDKCoreKit


public class EvergentGatewayAppDelegate {
    
    public static let sharedInstance = EvergentGatewayAppDelegate()
    private var clientUrl: String?
    
    private init() { }
    
    public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        return true
    }
 
    @available(iOS 9.0, *)
    public func application(_ application: UIApplication, openUrl: URL, sourceApplication: String?, annotation: Any) -> Bool {
        return FBSDKApplicationDelegate.sharedInstance().application(application, open: openUrl, sourceApplication: sourceApplication, annotation: annotation)
    }

    public func setClientUrl(url: String) {
        self.clientUrl = url
    }
    
    public func getClientUrl() -> String {
        return clientUrl!
    }
}
