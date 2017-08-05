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

class StationAnnotation: MKPointAnnotation {
    var pinCustomImageName: String!
    var station: StationModel!
    
}

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIPopoverPresentationControllerDelegate {
    
    @IBOutlet weak var stationsMapView: MKMapView!
    @IBOutlet weak var makeNoiseButton: UIButton!
    @IBOutlet weak var callHelpButton: UIButton!
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
    
    fileprivate func makeAnnotations() {
        var ano: [StationAnnotation] = []
        for s in stations {
            let location = CLLocationCoordinate2D(latitude: s.coordinate.latitude, longitude: s.coordinate.longitude)
            let pointAnnotation = StationAnnotation()
            pointAnnotation.coordinate = location
            if s.fullPercent == 0 {
                pointAnnotation.pinCustomImageName = "pin01"
            } else if s.fullPercent <= 0.2 {
                pointAnnotation.pinCustomImageName = "pin02"
            } else if s.fullPercent <= 0.5 {
                pointAnnotation.pinCustomImageName = "pin03"
            } else if s.fullPercent <= 0.8 {
                pointAnnotation.pinCustomImageName = "pin04"
            } else if s.fullPercent <= 1 {
                pointAnnotation.pinCustomImageName = "pin05"
            } else if s.fullPercent == 1 {
                pointAnnotation.pinCustomImageName = "pin06"
            } else {
                pointAnnotation.pinCustomImageName = "pin01"
            }
            
            pointAnnotation.station = s
            stationsMapView.addAnnotation(pointAnnotation)
            ano.append(pointAnnotation)
        }
        self.annotations = ano
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
        if firstEnter {
            self.firstEnter = false
            let region = MKCoordinateRegionMake(self.currentLocation, MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            stationsMapView.setRegion(region, animated: true)
        }
    }
}
