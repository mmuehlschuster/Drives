//
//  AcceptRequestViewController.swift
//  Drives
//
//  Created by Manuel Mühlschuster on 21.08.18.
//  Copyright © 2018 Manuel Mühlschuster. All rights reserved.
//

import UIKit
import MapKit
import FirebaseDatabase

class AcceptRequestViewController: UIViewController {

    @IBOutlet weak var map: MKMapView!
    @IBOutlet weak var acceptButton: UIButton!
    
    var requestLocation = CLLocationCoordinate2D()
    var driverLocation = CLLocationCoordinate2D()
    var requestEmail = ""
    
    let ref = Database.database().reference()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: requestLocation, span: span)
        map.setRegion(region, animated: true)
        
        let annotaion = MKPointAnnotation()
        annotaion.coordinate = requestLocation
        annotaion.title = requestEmail
        map.addAnnotation(annotaion)
    }

    @IBAction func acceptTapped(_ sender: Any) {
        // update ride request
        
        ref.child("RideRequests").queryOrdered(byChild: "email").queryEqual(toValue: requestEmail).observe(.childAdded) { (snapshot) in
            snapshot.ref.updateChildValues(["driverLat": self.driverLocation.latitude, "driverLong": self.driverLocation.longitude])
            self.ref.child("RideRequests").removeAllObservers()
        }
        
        // get directions
        
        let requestCLLocation = CLLocation(latitude: requestLocation.latitude, longitude: requestLocation.longitude)
        
        CLGeocoder().reverseGeocodeLocation(requestCLLocation) { (placemarks, error) in
            if let placemarks = placemarks {
                if !placemarks.isEmpty {
                    let placemark = MKPlacemark(placemark: placemarks.first!)
                    let mapItem = MKMapItem(placemark: placemark)
                    mapItem.name = self.requestEmail
                    
                    let options = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                    mapItem.openInMaps(launchOptions: options)
                }
            }
        }
    }
}
