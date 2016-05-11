//
//  ViewController.swift
//  Incognito
//
//  Created by Corinne Krych on 28/02/15.
//  Copyright (c) 2015 raywenderlich. All rights reserved.
//

import UIKit
import MobileCoreServices
import AssetsLibrary

// TODO string extension
extension String {
  public func urlEncode() -> String {
    let encodedURL = CFURLCreateStringByAddingPercentEscapes(
      nil,
      self as NSString,
      nil,
      "!@#$%&*'();:=+,/?[]",
      CFStringBuiltInEncodings.UTF8.rawValue)
    return encodedURL as String
  }
}

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIGestureRecognizerDelegate {
  var imagePicker = UIImagePickerController()
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var hatImage: UIImageView!
  @IBOutlet weak var glassesImage: UIImageView!
  @IBOutlet weak var moustacheImage: UIImageView!
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  // MARK: - Gesture Action
  
  @IBAction func move(recognizer: UIPanGestureRecognizer) {
    //return
    let translation = recognizer.translationInView(self.view)
    recognizer.view!.center = CGPoint(x:recognizer.view!.center.x + translation.x,
                                      y:recognizer.view!.center.y + translation.y)
    recognizer.setTranslation(CGPointZero, inView: self.view)
  }
  
  @IBAction func pinch(recognizer: UIPinchGestureRecognizer) {
    recognizer.view!.transform = CGAffineTransformScale(recognizer.view!.transform,
                                                        recognizer.scale, recognizer.scale)
    recognizer.scale = 1
  }
  
  @IBAction func rotate(recognizer: UIRotationGestureRecognizer) {
    recognizer.view!.transform = CGAffineTransformRotate(recognizer.view!.transform, recognizer.rotation)
    recognizer.rotation = 0
    
  }
  
  // MARK: - Menu Action
  
  @IBAction func openCamera(sender: AnyObject) {
    openPhoto()
  }
  
  @IBAction func hideShowHat(sender: AnyObject) {
    hatImage.hidden = !hatImage.hidden
  }
  
  @IBAction func hideShowGlasses(sender: AnyObject) {
    glassesImage.hidden = !glassesImage.hidden
  }
  
  @IBAction func hideShowMoustache(sender: AnyObject) {
    moustacheImage.hidden = !moustacheImage.hidden
  }
  var isObserved = false
  @IBAction func share(sender: AnyObject) {
    // TODO: your turn to code it!
    let clientID = "527780956271-uilmvmkbmed5s4hn1r4icis2e6iskpkk.apps.googleusercontent.com"
    let clientSecret = "1ympZ7yzrdEW_apPyllZPeqS"
    
    let baseURL = NSURL(string: "https://accounts.google.com")
    let scope = "https://www.googleapis.com/auth/drive".urlEncode()
    let redirect_uri = "com.access.IncognitoT:/oauth2Callback"
    
    if !isObserved {
      _ = NSNotificationCenter.defaultCenter().addObserverForName(
        "AGAppLaunchedWithURLNotification",
        object: nil,
        queue: nil,
        usingBlock: { (notification: NSNotification!) -> Void in
          let code = self.extractCode(notification)
          
          let manager = AFOAuth2Manager(baseURL: baseURL,
            clientID: clientID,
            secret: clientSecret)
          manager.useHTTPBasicAuthentication = false
          
          manager.authenticateUsingOAuthWithURLString("o/oauth2/token",
            code: code,
            redirectURI: redirect_uri,
            success: { (cred: AFOAuthCredential!) -> Void in
              
              manager.requestSerializer.setValue("Bearer \(cred.accessToken)",
                forHTTPHeaderField: "Authorization")
              
              manager.POST("https://www.googleapis.com/upload/drive/v2/files",
                parameters: nil,
                constructingBodyWithBlock: { (form: AFMultipartFormData!) -> Void in
                  form.appendPartWithFileData(self.snapshot(),
                    name:"name",
                    fileName:"fileName",
                    mimeType:"image/jpeg")
                }, success: { (op:AFHTTPRequestOperation!, obj:AnyObject!) -> Void in
                  self.presentAlert("Success", message: "Successfully uploaded!")
                }, failure: { (op: AFHTTPRequestOperation!, error: NSError!) -> Void in
                  self.presentAlert("Error", message: error!.localizedDescription)
              })
          }) { (error: NSError!) -> Void in
            self.presentAlert("Error", message: error!.localizedDescription)
          }
      })
      isObserved = true
    }
    
    // 3 calculate final url
    let params = "?scope=\(scope)&redirect_uri=\(redirect_uri)&client_id=\(clientID)&response_type=code"
    // 4 open an external browser
    UIApplication.sharedApplication().openURL(NSURL(string: "https://accounts.google.com/o/oauth2/auth\(params)")!)
  }
  
  // TODO add extractCode: method implementation
  func extractCode(notification: NSNotification) -> String? {
    let url: NSURL? = (notification.userInfo as!
      [String: AnyObject])[UIApplicationLaunchOptionsURLKey] as? NSURL
    
    // [1] extract the code from the URL
    return self.parametersFromQueryString(url?.query)["code"]
  }
  
  // TODO add parametersFromQueryString: method implementation
  func parametersFromQueryString(queryString: String?) -> [String: String] {
    var parameters = [String: String]()
    if (queryString != nil) {
      var parameterScanner: NSScanner = NSScanner(string: queryString!)
      var name:NSString? = nil
      var value:NSString? = nil
      while (parameterScanner.atEnd != true) {
        name = nil;
        parameterScanner.scanUpToString("=", intoString: &name)
        parameterScanner.scanString("=", intoString:nil)
        value = nil
        parameterScanner.scanUpToString("&", intoString:&value)
        parameterScanner.scanString("&", intoString:nil)
        if (name != nil && value != nil) {
          parameters[name!.stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!]
            = value!.stringByReplacingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        }
      }
    }
    return parameters
  }
  
  // MARK: - UIImagePickerControllerDelegate
  
  func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
    imagePicker.dismissViewControllerAnimated(true, completion: nil)
    imageView.image = info[UIImagePickerControllerOriginalImage] as? UIImage
  }
  
  // MARK: - UIGestureRecognizerDelegate
  
  func gestureRecognizer(_: UIGestureRecognizer,
                         shouldRecognizeSimultaneouslyWithGestureRecognizer:UIGestureRecognizer) -> Bool {
    return true
  }
  
  // MARK: - Private functions
  
  private func openPhoto() {
    imagePicker.sourceType = UIImagePickerControllerSourceType.SavedPhotosAlbum
    imagePicker.delegate = self
    presentViewController(imagePicker, animated: true, completion: nil)
  }
  
  func presentAlert(title: String, message: String) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
    alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
    self.presentViewController(alert, animated: true, completion: nil)
  }
  
  func snapshot() -> NSData {
    UIGraphicsBeginImageContext(self.view.frame.size)
    self.view.layer.renderInContext(UIGraphicsGetCurrentContext()!)
    let fullScreenshot = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    UIImageWriteToSavedPhotosAlbum(fullScreenshot, nil, nil, nil)
    return UIImageJPEGRepresentation(fullScreenshot, 0.5)!
  }
  
}

