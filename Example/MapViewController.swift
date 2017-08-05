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
import TwilioVideo

class StationAnnotation: MKPointAnnotation {
    var pinCustomImageName: String!
    var station: StationModel!
    
}

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UIPopoverPresentationControllerDelegate {

    // Configure access token manually for testing, if desired! Create one manually in the console
    // at https://www.twilio.com/user/account/video/dev-tools/testing-tools
    var accessToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImN0eSI6InR3aWxpby1mcGE7dj0xIn0.eyJqdGkiOiJTSzY2NzdiMmVkYWU1Yjk0M2NlMTk3ZTllNWI1NWVlZDJhLTE1MDE5NzM2MjMiLCJpc3MiOiJTSzY2NzdiMmVkYWU1Yjk0M2NlMTk3ZTllNWI1NWVlZDJhIiwic3ViIjoiQUNmZDFjNTZjODkxZjA4ODM1YWUwYTE3YmIxOWI0ZDkxNCIsImV4cCI6MTUwMTk3NzIyMywiZ3JhbnRzIjp7ImlkZW50aXR5IjoiVmljdGltIiwidmlkZW8iOnt9fX0.MWXhUcTt5Vp2359wFZ4BGnj4qpBPbGbTN8lGWdGVgbU"
    
    // Video SDK components
    var room: TVIRoom?
    var camera: TVICameraCapturer?
    var localVideoTrack: TVILocalVideoTrack?
    var localAudioTrack: TVILocalAudioTrack?
    var participant: TVIParticipant?
    @IBOutlet var remoteView: TVIVideoView!
    
    
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
                    for station in self.stations {
                        let geotification = Geotification(coordinate: station.coordinate, radius: 500.0, identifier: "", note: "", eventType: EventType.onEntry)
                        self.startMonitoring(geotification: geotification)
                    }
                }
                
            case .failure:
                print("getStations failure")
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func logMessage(messageText: String) {
        print(messageText)
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
        self.showRoomUI(inRoom: false)
        
        UIView.animate(withDuration: 0.3,
                       delay: 0.0,
                       options: UIViewAnimationOptions.curveEaseOut,
                       animations: { () -> Void in
                        self.sosView.frame.origin.y = 0
                        self.view?.layoutIfNeeded()
        }, completion: { (finished) -> Void in
            self.activityView.startAnimating()
            self.connect()
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
    
    func connect() {
        // Configure access token either from server or manually.
        
        // Prepare local media which we will share with Room Participants.
        self.prepareLocalMedia()
        
        // Preparing the connect options with the access token that we fetched (or hardcoded).
        let connectOptions = TVIConnectOptions.init(token: accessToken) { (builder) in
            
            // Use the local media that we prepared earlier.
            builder.audioTracks = self.localAudioTrack != nil ? [self.localAudioTrack!] : [TVILocalAudioTrack]()
            builder.videoTracks = self.localVideoTrack != nil ? [self.localVideoTrack!] : [TVILocalVideoTrack]()
            
            // The name of the Room where the Client will attempt to connect to. Please note that if you pass an empty
            // Room `name`, the Client will create one for you. You can get the name or sid from any connected Room.
            builder.roomName = "NightWatch"
        }
        
        // Connect to the Room using the options we provided.
        room = TwilioVideo.connect(with: connectOptions, delegate: self)
        
        
    }

    func prepareLocalMedia() {
        
        // We will share local audio and video when we connect to the Room.
        // MARK: Private
            
            // Preview our local camera track in the local video preview view.
            camera = TVICameraCapturer(source: .frontCamera, delegate: self)
            localVideoTrack = TVILocalVideoTrack.init(capturer: camera!)
            if (localVideoTrack == nil) {
                logMessage(messageText: "Failed to create video track")
            }

        
        // Create an audio track.
        if (localAudioTrack == nil) {
            localAudioTrack = TVILocalAudioTrack.init()
            
            if (localAudioTrack == nil) {
                logMessage(messageText: "Failed to create audio track")
            }
        }
    }
    
    func showRoomUI(inRoom: Bool) {
        self.remoteView.isHidden = !inRoom
        self.activityView.isHidden = inRoom
    }
    
    func cleanupRemoteParticipant() {
        if ((self.participant) != nil) {
            if ((self.participant?.videoTracks.count)! > 0) {
                self.participant?.videoTracks[0].removeRenderer(self.remoteView!)
                self.showRoomUI(inRoom: false)
            }
        }
        self.participant = nil
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
    
    // add geofencing
    func region(withGeotification geotification: Geotification) -> CLCircularRegion {
        // 1
        let region = CLCircularRegion(center: geotification.coordinate, radius: geotification.radius, identifier: geotification.identifier)
        // 2
        region.notifyOnEntry = (geotification.eventType == .onEntry)
        region.notifyOnExit = !region.notifyOnEntry
        return region
    }
    
    func startMonitoring(geotification: Geotification) {
        // 1
        if !CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            //showAlert(withTitle:"Error", message: "Geofencing is not supported on this device!")
            return
        }
        // 2
        if CLLocationManager.authorizationStatus() != .authorizedAlways {
            //showAlert(withTitle:"Warning", message: "Your geotification is saved but will only be activated once you grant Geotify permission to access the device location.")
        }
        // 3
        let region = self.region(withGeotification: geotification)
        // 4
        locationManager.startMonitoring(for: region)
    }
}

// MARK: TVIRoomDelegate
extension MapViewController : TVIRoomDelegate {
    func didConnect(to room: TVIRoom) {
        
        // At the moment, this example only supports rendering one Participant at a time.
        
        logMessage(messageText: "Connected to room \(room.name) as \(String(describing: room.localParticipant?.identity))")
        
        if (room.participants.count > 0) {
            self.participant = room.participants[0]
            self.participant?.delegate = self
        }
        
        self.showRoomUI(inRoom: true)
    }
    
    func room(_ room: TVIRoom, didDisconnectWithError error: Error?) {
        logMessage(messageText: "Disconncted from room \(room.name), error = \(String(describing: error))")
        
        self.cleanupRemoteParticipant()
        self.room = nil
        
        self.showRoomUI(inRoom: false)
    }
    
    func room(_ room: TVIRoom, didFailToConnectWithError error: Error) {
        logMessage(messageText: "Failed to connect to room with error")
        self.room = nil
        
        self.showRoomUI(inRoom: false)
    }
    
    func room(_ room: TVIRoom, participantDidConnect participant: TVIParticipant) {
        if (self.participant == nil) {
            self.participant = participant
            self.participant?.delegate = self
        }
        logMessage(messageText: "Room \(room.name), Participant \(participant.identity) connected")
    }
    
    func room(_ room: TVIRoom, participantDidDisconnect participant: TVIParticipant) {
        if (self.participant == participant) {
            cleanupRemoteParticipant()
        }
        logMessage(messageText: "Room \(room.name), Participant \(participant.identity) disconnected")
    }
}

// MARK: TVIParticipantDelegate
extension MapViewController : TVIParticipantDelegate {
    func participant(_ participant: TVIParticipant, addedVideoTrack videoTrack: TVIVideoTrack) {
        logMessage(messageText: "Participant \(participant.identity) added video track")
        
        if (self.participant == participant) {
            self.remoteView.delegate = self
            videoTrack.addRenderer(self.remoteView!)
        }
    }
    
    func participant(_ participant: TVIParticipant, removedVideoTrack videoTrack: TVIVideoTrack) {
        logMessage(messageText: "Participant \(participant.identity) removed video track")
        
        if (self.participant == participant) {
            videoTrack.removeRenderer(self.remoteView)
            self.showRoomUI(inRoom: false)
        }
    }
    
    func participant(_ participant: TVIParticipant, addedAudioTrack audioTrack: TVIAudioTrack) {
        logMessage(messageText: "Participant \(participant.identity) added audio track")
        
    }
    
    func participant(_ participant: TVIParticipant, removedAudioTrack audioTrack: TVIAudioTrack) {
        logMessage(messageText: "Participant \(participant.identity) removed audio track")
    }
    
    func participant(_ participant: TVIParticipant, enabledTrack track: TVITrack) {
        var type = ""
        if (track is TVIVideoTrack) {
            type = "video"
        } else {
            type = "audio"
        }
        logMessage(messageText: "Participant \(participant.identity) enabled \(type) track")
    }
    
    func participant(_ participant: TVIParticipant, disabledTrack track: TVITrack) {
        var type = ""
        if (track is TVIVideoTrack) {
            type = "video"
        } else {
            type = "audio"
        }
        logMessage(messageText: "Participant \(participant.identity) disabled \(type) track")
    }
}

// MARK: TVIVideoViewDelegate
extension MapViewController : TVIVideoViewDelegate {
    func videoView(_ view: TVIVideoView, videoDimensionsDidChange dimensions: CMVideoDimensions) {
        self.view.setNeedsLayout()
    }
}

// MARK: TVICameraCapturerDelegate
extension MapViewController : TVICameraCapturerDelegate {
    func cameraCapturer(_ capturer: TVICameraCapturer, didStartWith source: TVICameraCaptureSource) {
        //self.previewView.shouldMirror = (source == .frontCamera)
    }
}

