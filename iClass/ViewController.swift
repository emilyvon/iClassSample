//
//  ViewController.swift
//  iClass
//
//  Created by Chandrasegaran Senthil Kumaran on 5/2/16.
//  Copyright © 2016 SenthilKumaran. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit

class ViewController: UIViewController {
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if NSUserDefaults.standardUserDefaults().valueForKey(KEY_UID) != nil {
            self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
        }
    }
    
    
    @IBAction func fbBtnPressed(sender: UIButton!){
        let facebookLogin = FBSDKLoginManager()

        facebookLogin.logInWithReadPermissions(["email"], fromViewController: self) { (facebookResult: FBSDKLoginManagerLoginResult!, facebookError: NSError!) in
            
            if facebookError != nil {
                print("Facebook login failed. Error \(facebookError)")
            } else {
                let accessToken = FBSDKAccessToken.currentAccessToken().tokenString
                print("Successfully logged in with facebook. \(accessToken)")
                
                DataService.ds.REF_BASE.authWithOAuthProvider("facebook", token: accessToken, withCompletionBlock: { error, authData  in
                
                    if error != nil {
                        print("Login failed. \(error)")
                    }else {
                        print("Logged In!\(authData)")
                        
                        let user = ["provider": authData.provider!] // swift dictionary
                        DataService.ds.createFirebaseUser(authData.uid, user: user)
                        
                        NSUserDefaults.standardUserDefaults().setValue(authData.uid, forKey: KEY_UID)
                        self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
                    }
                    
                })
                
            }
        }
        
        
       /*
 
        } */

        
   /*      facebookLogin.logInWithReadPermissions(["Email"]) { ( facebookResult: FBSDKLoginManagerLoginResult!, facebookError: NSError!) in
            
            if facebookError != nil {
                print("Facebook login failed. Error \(facebookError)")
            } else {
                let accessToken = FBSDKAccessToken.currentAccessToken().tokenString
                print("Successfully logged in with facebook. \(accessToken)")
            }
            
        } */
        
    }

    
    @IBAction func attemptLogin (sender: UIButton!){
        
        if let email = emailField.text where email != "", let pwd = passwordField.text where pwd != "" {
            
            DataService.ds.REF_BASE.authUser(email, password: pwd, withCompletionBlock: { error, authData in // will login the user if he has already signed up
               
                if error != nil {
                    
                    print(error)
                    
                    if error.code == STATUS_ACCOUNT_NONEXIST {
                        DataService.ds.REF_BASE.createUser(email, password: pwd, withValueCompletionBlock: { error, result in // result is a dictionary // creates new account given that he's a new user
                            
                            if error != nil {
                                self.showErrorAlert("Could not create account", msg: "Problem creatiing account. Try something else")
                            } else {
                                NSUserDefaults.standardUserDefaults().setValue(result[KEY_UID], forKey: KEY_UID) // result is a dictionary
                                
                                //DataService.ds.REF_BASE.authUser(email, password: pwd, withCompletionBlock: nil) // the new users gets signed in
                                
                                DataService.ds.REF_BASE.authUser(email, password: pwd, withCompletionBlock: {
                                    err, authData in
                                    
                                    let user = ["provider": authData.provider!] // swift dictionary
                                    DataService.ds.createFirebaseUser(authData.uid, user: user)
                                    
                                })
                                
                                self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
                                
                            }
                        })
                            
                    
                    } else {
                        self.showErrorAlert("Could not login", msg: "Please check your username or password")
                    }
                    
                } else {
                    self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
                }
                
            })
            
            
        } else {
            showErrorAlert("Email and Password Required", msg: "You must enter an email and a password")
        }
    }
    
    
    func showErrorAlert(title: String, msg: String){
        let alert = UIAlertController(title: title, message: msg, preferredStyle: .Alert)
        let action = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil)
        alert.addAction(action)
        presentViewController(alert, animated: true, completion: nil)
    }

}

