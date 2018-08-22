//
//  DriverViewController.swift
//  Drives
//
//  Created by Manuel Mühlschuster on 21.08.18.
//  Copyright © 2018 Manuel Mühlschuster. All rights reserved.
//

import UIKit
import MapKit
import FirebaseAuth
import FirebaseDatabase

class DriverViewController: UITableViewController {

    @IBOutlet weak var logoutButton: UIBarButtonItem!
    
    let auth = Auth.auth()
    let ref = Database.database().reference()
    
    let locationManager = CLLocationManager()
    var driverLocation = CLLocationCoordinate2D()
    
    var rideRequests : [DataSnapshot] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        ref.child("RideRequests").observe(.childAdded) { (snapshot) in
            if let rideRequest = snapshot.value as? [String: Any] {
                if rideRequest["driverLat"] as? Double == nil {
                    self.rideRequests.append(snapshot)
                    self.tableView.reloadData()
                }
            }
        }
        
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { (timer) in
            self.tableView.reloadData()
        }
    }
    
    @IBAction func logoutTapped(_ sender: Any) {
        try? auth.signOut()
        navigationController?.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rideRequests.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "rideRequestCell", for: indexPath)

        let snapshot = rideRequests[indexPath.row]

        if let rideRequest = snapshot.value as? [String: Any] {
            if let email = rideRequest["email"] as? String {
                
                if let lat = rideRequest["lat"] as? Double {
                    if let long = rideRequest["long"] as? Double {
                        
                        let driverCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
                        let passengerCLLocation = CLLocation(latitude: lat, longitude: long)
                        
                        let distance = driverCLLocation.distance(from: passengerCLLocation) / 1000
                        let roundedDistance = round(distance * 100) / 100
                        
                        cell.textLabel?.text = "\(email) is \(roundedDistance)km away"
                    }
                }
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let snapshot = rideRequests[indexPath.row]
        performSegue(withIdentifier: "acceptSegue", sender: snapshot)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? AcceptRequestViewController {
            if let snapshot = sender as? DataSnapshot {
                if let rideRequest = snapshot.value as? [String: Any] {
                    if let email = rideRequest["email"] as? String {
                        destination.requestEmail = email
                        
                        if let lat = rideRequest["lat"] as? Double {
                            if let long = rideRequest["long"] as? Double {
                                let location = CLLocationCoordinate2D(latitude: lat, longitude: long)
                                destination.requestLocation = location
                                destination.driverLocation = driverLocation
                            }
                        }
                    }
                }
            }
        }
    }
}

extension DriverViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let coordinate = manager.location?.coordinate {
            driverLocation = coordinate
        }
    }
}
