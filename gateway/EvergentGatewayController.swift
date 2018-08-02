//
//  EvergentGatewayController.swift
//  gateway
//
//  Created by Aminul Hasan on 5/24/18.
//  Copyright © 2018 Evergent. All rights reserved.
//
import FBSDKCoreKit
import Foundation
import UIKit
import FBSDKLoginKit

enum EntryMode {
    case SIGNUPEMAIL
    case SIGNUPMOBILE
    case SIGNINMOBILE
    case SIGNINEMAIL
    
    public func isSignup() -> Bool {
        return (self == EntryMode.SIGNUPEMAIL || self == EntryMode.SIGNUPMOBILE)
    }
    
    public func isSignin() -> Bool {
        return (self == EntryMode.SIGNINMOBILE || self == EntryMode.SIGNINEMAIL)
    }
}

public class EvergentGatewayController: UIViewController, UIWebViewDelegate {
    
    var webview: UIWebView?
    
    var clientUrl: String = EvergentGatewayAppDelegate.sharedInstance.getClientUrl()
    var queryItems: [URLQueryItem] = []
    var callbackUrl: String = "https://dev-web-hooq.evergent.com/fbconnect"
    var entryMode: EntryMode = EntryMode.SIGNUPEMAIL
    var indicator: UIActivityIndicatorView?
    
    /// fbiosconnect == signin up / sign up mobile
    /// signinemail = signin flow
    /// signinmobile = signin flow
    
    override public func viewDidLoad() {
        
        indicator = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.gray)
        indicator?.frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        indicator?.center = view.center
        view.addSubview(indicator!)
        indicator?.bringSubview(toFront: view)
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        webview = UIWebView(frame: self.view.bounds)
        let clientUrl = URL(string: self.clientUrl)
        let request = URLRequest(url: clientUrl!)
        
        if (clientUrl?.getQueryString(parameter: "returnUrl") != nil) {
            queryItems.append(URLQueryItem(name: "returnUrl", value: clientUrl?.getQueryString(parameter: "returnUrl")))
        }
        
        if (clientUrl?.getQueryString(parameter: "deviceName") != nil) {
            queryItems.append(URLQueryItem(name: "deviceName", value: clientUrl?.getQueryString(parameter: "deviceName")))
        }
        
        if (clientUrl?.getQueryString(parameter: "deviceType") != nil) {
            queryItems.append(URLQueryItem(name: "deviceType", value: clientUrl?.getQueryString(parameter: "deviceType")))
        }
        
        if (clientUrl?.getQueryString(parameter: "serialNo") != nil) {
            queryItems.append(URLQueryItem(name: "serialNo", value: clientUrl?.getQueryString(parameter: "serialNo")))
        }
        
        if (clientUrl?.getQueryString(parameter: "modelNo") != nil) {
            queryItems.append(URLQueryItem(name: "modelNo", value: clientUrl?.getQueryString(parameter: "modelNo")))
        }
        
        // TODO: Remove IP later
        if (clientUrl?.getQueryString(parameter: "ip") != nil) {
            queryItems.append(URLQueryItem(name: "ip", value: clientUrl?.getQueryString(parameter: "ip")))
        }
        
        queryItems.append(URLQueryItem(name: "callingAction", value: "fbiosconnect"))
        
        self.view.addSubview(webview!)
        webview?.delegate = self
        webview?.loadRequest(request)
    }
    
    public func showError(title: String, msg: String) {
        let alert = UIAlertController(title: title, message: msg, preferredStyle: UIAlertControllerStyle.alert)
        let alertAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default)
        {
            (UIAlertAction) -> Void in
            alert.dismiss(animated: true) {
                () -> Void in
            }
        }
        alert.addAction(alertAction)
        present(alert, animated: true)
        {
            () -> Void in
        }
    }
    
    public func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if (request.url?.scheme == "https") {
            if ((request.url?.host == "m.facebook.com" || request.url?.host == "mobile.facebook.com")) {
                fbLoginInitiate()
                return false
            }
        }
        return true
    }
    
    public func webViewDidFinishLoad(_ webView: UIWebView) {
        if let url = webView.request?.url?.absoluteURL {
            print(url)
            if url.absoluteString.contains("/signinemail") {
                entryMode = EntryMode.SIGNINEMAIL
            } else if url.absoluteString.contains("/signinmobile") {
                entryMode = EntryMode.SIGNINMOBILE
            } else if url.absoluteString.contains("/fbiosconnect") || url.absoluteString.contains("/signupemail") {
                entryMode = EntryMode.SIGNUPEMAIL
            } else if url.absoluteString.contains("/signupmobile") {
                entryMode = EntryMode.SIGNUPMOBILE
            }
            updateCallingAction()
        }
    }
    
    private func getCurrentCallingAction() -> String {
        switch self.entryMode {
        case .SIGNUPMOBILE :
            return "signupmobile"
        case .SIGNUPEMAIL:
            return "signupemail"
        case .SIGNINMOBILE:
            return "signinmobile"
        case .SIGNINEMAIL:
            return "signinemail"
        }
    }
    
    public func webViewDidStartLoad(_ webView: UIWebView) {
    }
    
    private func updateCallingAction() {
        queryItems.removeLast()
        queryItems.append(URLQueryItem(name: "callingAction", value: getCurrentCallingAction()))
    }
    
    func fbLoginInitiate() {
        let loginManager = FBSDKLoginManager()
        loginManager.logIn(withReadPermissions: ["public_profile", "email"], from: self, handler: {(result:FBSDKLoginManagerLoginResult?, error: Error?) -> Void in
            if (error != nil) {
                // Process error
                self.removeFbData()
                self.showError(title: "Error", msg: error?.localizedDescription ?? "Facebook error occured.")
            } else if result != nil && result!.isCancelled {
                // User Cancellation
                self.removeFbData()
                self.showError(title: "Error", msg: error?.localizedDescription ?? "Facebook error occured.")
            } else {
                //Success
                if result != nil && result!.grantedPermissions.contains("email") && result!.grantedPermissions.contains("public_profile") {
                    //Do work
                    self.fetchFacebookProfile()
                } else {
                    //Handle error
                    self.showError(title: "Error", msg: "Could not receive facebook details.")
                }
            }
            })
    }
    
    func removeFbData() {
        //Remove FB Data
        let fbManager = FBSDKLoginManager()
        fbManager.logOut()
        FBSDKAccessToken.setCurrent(nil)
    }
    
    func fetchFacebookProfile()
    {
        if FBSDKAccessToken.current() != nil {
            let parameters = ["fields": "id, first_name, last_name, email"]
            let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: parameters)
            graphRequest.start(completionHandler: { (connection, result, error) -> Void in
                
                if ((error) != nil) {
                    //Handle error
                    self.showError(title: "Error", msg: error?.localizedDescription ?? "Facebook error occured.")
                } else {
                    let accessToken = FBSDKAccessToken.current().tokenString
                    
                    if var fbDic = result as? [String: Any] {
                        fbDic.updateValue(accessToken!, forKey: "access_token")
                        var callbackURL = URLComponents(string: self.callbackUrl)
                        
                        if self.entryMode.isSignin() {
                            if let urlComponents = URLComponents(string: (self.webview?.request?.url?.absoluteURL.absoluteString)!) {
                                var signinQueryItems = urlComponents.queryItems
                                signinQueryItems?.append(URLQueryItem(name: "callingAction", value: self.getCurrentCallingAction()))
                                callbackURL?.queryItems = signinQueryItems
                                print(callbackURL?.url! ?? "malformed url")
                            } else {
                                self.showError(title: "Error", msg: "Technical error occured.")
                            }
                        } else {
                            callbackURL?.queryItems = self.queryItems
                        }
                        
                        var request = URLRequest(url: (callbackURL?.url)!)
                        request.httpMethod = "POST"
                        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                        do {
                            let json = try JSONSerialization.data(withJSONObject: fbDic, options: JSONSerialization.WritingOptions(rawValue: 0))
                            let dataString = String(data: json, encoding: String.Encoding.utf8)
                            let postData: Data = dataString!.data(using: String.Encoding.utf8, allowLossyConversion: true)!
                            request.httpBody = postData
                            print(dataString)
                            self.webview?.loadRequest(request)
                        } catch {
                            self.showError(title: "Error", msg: error.localizedDescription)
                        }

                    }
                }
            })
        }
    }
}

extension URL {
    func getQueryString(parameter: String) -> String? {
        return URLComponents(url: self, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first { $0.name == parameter }?
            .value
    }
}
    
