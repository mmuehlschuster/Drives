//
//  PassengerViewController.swift
//  Drives
//
//  Created by Manuel Mühlschuster on 21.08.18.
//  Copyright © 2018 Manuel Mühlschuster. All rights reserved.
//

import UIKit
import MapKit
import FirebaseAuth
import FirebaseDatabase

class PassengerViewController: UIViewController {

    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var callADriverButton: UIButton!
    
    let locationManager = CLLocationManager()
    var passengerLocation = CLLocationCoordinate2D()
    var driverLocation = CLLocationCoordinate2D()
    var driverHasBeenCalled = false
    var driverOnTheWay = false
    
    var auth = Auth.auth()
    var ref = Database.database().reference()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        if let email = auth.currentUser?.email {
            ref.child("RideRequests").queryOrdered(byChild: "email").queryEqual(toValue: email).observe(.childAdded) { (snapshot) in
                self.driverHasBeenCalled = true
                self.callADriverButton.setTitle("Cancel Driver", for: .normal)
                self.ref.child("RideRequests").removeAllObservers()
                
                if let rideRequest = snapshot.value as? [String: Any] {
                    if let driverLat = rideRequest["driverLat"] as? Double {
                        if let driverLong = rideRequest["driverLong"] as? Double {
                            self.driverLocation = CLLocationCoordinate2D(latitude: driverLat, longitude: driverLong)
                            self.driverOnTheWay = true
                            self.displayDriverAndPassenger()
                            
                            if let email = self.auth.currentUser?.email {
                                self.ref.child("RideRequests").queryOrdered(byChild: "email").queryEqual(toValue: email).observe(.childChanged) { (snapshot) in
                                    if let rideRequest = snapshot.value as? [String: Any] {
                                        if let driverLat = rideRequest["driverLat"] as? Double {
                                            if let driverLong = rideRequest["driverLong"] as? Double {
                                                self.driverLocation = CLLocationCoordinate2D(latitude: driverLat, longitude: driverLong)
                                                self.driverOnTheWay = true
                                                self.displayDriverAndPassenger()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    @IBAction func logoutTapped(_ sender: Any) {
        try? auth.signOut()
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func callTapped(_ sender: Any) {
        if !driverOnTheWay {
            if let email = auth.currentUser?.email {
                if driverHasBeenCalled {
                    ref.child("RideRequests").queryOrdered(byChild: "email").queryEqual(toValue: email).observe(.childAdded) { (snapshot) in
                        snapshot.ref.removeValue()
                        self.ref.child("RideRequests").removeAllObservers()
                    }
                    
                    driverHasBeenCalled = false
                    callADriverButton.setTitle("Call A Driver", for: .normal)
                } else {
                    let rideRequest : [String: Any] = ["email": email, "lat": passengerLocation.latitude, "long": passengerLocation.longitude]
                    
                    ref.child("RideRequests").childByAutoId().setValue(rideRequest)
                    driverHasBeenCalled = true
                    callADriverButton.setTitle("Cancel Driver", for: .normal)
                }
            }
        }
    }
    
    func displayDriverAndPassenger() {
        let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
        let passengerCLLocation = CLLocation(latitude: passengerLocation.latitude, longitude: passengerLocation.longitude)
        
        let distance = driverCLLocation.distance(from: passengerCLLocation) / 1000
        let roundedDistance = round(distance * 100) / 100
        
        callADriverButton.setTitle("Your driver is \(roundedDistance)km away", for: .normal)
        
        map.removeAnnotations(map.annotations)
        
        let deltaLat = abs(driverLocation.latitude - passengerLocation.latitude) * 2 + 0.005
        let deltaLong = abs(driverLocation.longitude - passengerLocation.longitude) * 2 + 0.005
        
        let span = MKCoordinateSpan(latitudeDelta: deltaLat, longitudeDelta: deltaLong)
        let region = MKCoordinateRegion(center: passengerLocation, span: span)
        map.setRegion(region, animated: true)
        
        let passengerAnnotation = MKPointAnnotation()
        passengerAnnotation.coordinate = passengerLocation
        passengerAnnotation.title = "Your Location"
        map.addAnnotation(passengerAnnotation)
        
        let driverAnnotation = MKPointAnnotation()
        driverAnnotation.coordinate = driverLocation
        driverAnnotation.title = "Your Driver"
        map.addAnnotation(driverAnnotation)
    }
}

extension PassengerViewController : CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coordinate = manager.location?.coordinate {
            let center = CLLocationCoordinate2D(latitude: coordinate.latitude, longitude: coordinate.longitude)
            passengerLocation = center
            
            if driverOnTheWay {
                displayDriverAndPassenger()
            } else {
                let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                let region = MKCoordinateRegion(center: center, span: span)
                map.setRegion(region, animated: true)
                
                map.removeAnnotations(map.annotations)
                let annotation = MKPointAnnotation()
                annotation.coordinate = center
                map.addAnnotation(annotation)
            }
        }
    }
}
