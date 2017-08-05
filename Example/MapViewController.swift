//
//  MapViewController.swift
//  UbikeTracer
//
//  Created by rosa on 2017/7/22.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import AudioToolbox.AudioServices
import NVActivityIndicatorView


class StationAnnotation: MKPointAnnotation {
    var pinCustomImageName: String!
    var station: StationModel!
    
}

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIPopoverPresentationControllerDelegate {
    
    @IBOutlet weak var stationsMapView: MKMapView!
    @IBOutlet weak var makeNoiseButton: UIButton!
    @IBOutlet weak var callHelpButton: UIButton!
    @IBOutlet weak var sosView: UIView!
    @IBOutlet var activityView: NVActivityIndicatorView!
    
    //pass from appdelegate
    var stations: [StationModel]!
    
    var firstEnter = true
    let annotationReuseId = "pin"
    var annotations: [StationAnnotation] = []
    var locationManager = CLLocationManager()
    var currentLocation = CLLocationCoordinate2D()
    
    
    @IBAction func setUserInCenterButtonPressed(_ sender: UIBarButtonItem) {
        let region = MKCoordinateRegionMake(self.currentLocation, MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        stationsMapView.setRegion(region, animated: true)
    }
    
    public func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //location Manager
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 100
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        stationsMapView.delegate = self
        stationsMapView.mapType = MKMapType.standard
        stationsMapView.showsUserLocation = true

        StationManager.sharedInstance.getStations { result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    self.stations = StationManager.sharedInstance.stations
                    self.makeAnnotations()
                }
                
            case .failure:
                print("getStations failure")
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    @IBAction func playSound(_ sender: AnyObject) {
        let filename = "scream"
        let ext = "mp3"
        
        if let soundUrl = Bundle.main.url(forResource: filename, withExtension: ext) {
            var soundId: SystemSoundID = 0
            
            AudioServicesCreateSystemSoundID(soundUrl as CFURL, &soundId)
            
            AudioServicesAddSystemSoundCompletion(soundId, nil, nil, { (soundId, clientData) -> Void in
                AudioServicesDisposeSystemSoundID(soundId)
            }, nil)
            
            AudioServicesPlaySystemSound(soundId)
            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
        }
        
        
    }

    @IBAction func sos(_ sender: AnyObject) {
        // send an alert to backend
        let app = UIApplication.shared.delegate as! AppDelegate
        // update current user location to FB
        app.user?.updateChildValues(["sos": true])
        
        
        self.activityView.stopAnimating()
        self.view.addSubview(self.sosView)
        self.sosView.frame.origin.y = self.view.bounds.size.height
        
        UIView.animate(withDuration: 0.3,
                       delay: 0.0,
                       options: UIViewAnimationOptions.curveEaseOut,
                       animations: { () -> Void in
                        self.sosView.frame.origin.y = 0
                        self.view?.layoutIfNeeded()
        }, completion: { (finished) -> Void in
            self.activityView.startAnimating()
        })
    }
    
    fileprivate func makeAnnotations() {
        var ano: [StationAnnotation] = []
        for s in stations {
            let location = CLLocationCoordinate2D(latitude: s.coordinate.latitude, longitude: s.coordinate.longitude)
            let pointAnnotation = StationAnnotation()
            pointAnnotation.coordinate = location
            
            pointAnnotation.pinCustomImageName = "Pin"

            
            pointAnnotation.station = s
            stationsMapView.addAnnotation(pointAnnotation)
            ano.append(pointAnnotation)
        }
        self.annotations = ano
    }
    
   
    @IBAction func cencelReport(_ sender:AnyObject) {
        self.sosView.removeFromSuperview()
    }
    
    //    MARK: - Custom Annotation
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is StationAnnotation else {
            return nil
        }
        
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationReuseId)
        
        if annotationView == nil {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationReuseId)
            annotationView?.canShowCallout = false
        } else {
            annotationView?.annotation = annotation
        }
        
        let cpa = annotation as! StationAnnotation
        
        annotationView!.image = UIImage(named:cpa.pinCustomImageName)
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation as? StationAnnotation else {
            return
        }
        let region = MKCoordinateRegionMake(annotation.coordinate , MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        stationsMapView.setRegion(region, animated: true)
        //Custom xib
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView){
        for childView: AnyObject in view.subviews{
            childView.removeFromSuperview()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let userLocation = locations.first else {
            return
        }
        self.currentLocation = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        
        let app = UIApplication.shared.delegate as! AppDelegate
        // update current user location to FB
        app.user?.updateChildValues(["loc": [
                                         "lat": self.currentLocation.latitude,
                                         "lng": self.currentLocation.longitude
                                    ]
        ])


        if firstEnter {
            self.firstEnter = false
            let region = MKCoordinateRegionMake(self.currentLocation, MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            stationsMapView.setRegion(region, animated: true)
        }
    }
}
