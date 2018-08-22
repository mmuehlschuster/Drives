//
//  LoginViewController.swift
//  Drives
//
//  Created by Manuel Mühlschuster on 21.08.18.
//  Copyright © 2018 Manuel Mühlschuster. All rights reserved.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var driverPassengerSwitch: UISwitch!
    
    @IBOutlet weak var topButton: UIButton!
    @IBOutlet weak var bottomButton: UIButton!
    
    @IBOutlet weak var driverPassengerStackView: UIStackView!
    
    lazy var auth = Auth.auth()
    var signUpMode = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func topTapped(_ sender: UIButton) {
        if emailTextField.text == "" || passwordTextField.text == "" {
            displayAlert(title: "Missing Information", message: "Please enter email and password!")
        } else {
            if let email = emailTextField.text, let password = passwordTextField.text {
                if signUpMode {
                    auth.createUser(withEmail: email, password: password) { (user, error) in
                        if error != nil {
                            self.displayAlert(title: "Error", message: error!.localizedDescription)
                        } else {
                            if self.driverPassengerSwitch.isOn {
                                // Passenger
                                let req = self.auth.currentUser?.createProfileChangeRequest()
                                req?.displayName = "Passenger"
                                req?.commitChanges(completion: nil)
                                self.performSegue(withIdentifier: "passengerSegue", sender: nil)
                            } else {
                                // Driver
                                let req = self.auth.currentUser?.createProfileChangeRequest()
                                req?.displayName = "Driver"
                                req?.commitChanges(completion: nil)
                                self.performSegue(withIdentifier: "driverSegue", sender: nil)
                            }
                        }
                    }
                } else {
                    auth.signIn(withEmail: email, password: password) { (user, error) in
                        if error != nil {
                            self.displayAlert(title: "Error", message: error!.localizedDescription)
                        } else {
                            if user?.displayName == "Passenger" {
                                self.performSegue(withIdentifier: "passengerSegue", sender: nil)
                            } else {
                                self.performSegue(withIdentifier: "driverSegue", sender: nil)
                            }
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func bottomTapped(_ sender: UIButton) {
        if signUpMode {
            topButton.setTitle("Login", for: .normal)
            bottomButton.setTitle("Sign up", for: .normal)
            
            driverPassengerStackView.isHidden = true
            signUpMode = false
        } else {
            topButton.setTitle("Sign up", for: .normal)
            bottomButton.setTitle("Login", for: .normal)
            
            driverPassengerStackView.isHidden = false
            signUpMode = true
        }
    }
    
    func displayAlert(title: String, message: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        present(alertController, animated: true, completion: nil)
    }
}

