//
//  CurrentLocationViewController.swift
//  MyLocations
//
//  Created by Chad on 1/5/18.
//  Copyright © 2018 Chad Williams. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData
import AudioToolbox

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate, CAAnimationDelegate {
  
  @IBOutlet weak var messageLabel: UILabel!
  @IBOutlet weak var latitudeLabel: UILabel!
  @IBOutlet weak var longitudeLabel: UILabel!
  @IBOutlet weak var addressLabel: UILabel!
  @IBOutlet weak var tagButton: UIButton!
  @IBOutlet weak var getButton: UIButton!
  @IBOutlet weak var latitudeTextLabel: UILabel!
  @IBOutlet weak var longitudeTextLabel: UILabel!
  @IBOutlet weak var containerView: UIView!
  
  @IBAction func getLocation() {
    let authStatus = CLLocationManager.authorizationStatus()
    if authStatus == .notDetermined {
      locationManager.requestWhenInUseAuthorization()
      return
    }
    
    if authStatus == .denied || authStatus == .restricted {
      showLocationServicesDeniedAlert()
      return
    }
    
    if logoVisible {
      hideLogoView()
    }
    
    if updatingLocation {
      stopLocationManager()
    } else {
      location = nil
      lastLocationError = nil
      placemark = nil
      lastGeoCodingError = nil
      startLocationManager()
    }
    
    updateLabels()
  }
  
  let locationManager = CLLocationManager()
  var location: CLLocation?
  var updatingLocation = false
  var lastLocationError: Error?
  
  let geocoder = CLGeocoder()
  var placemark: CLPlacemark?
  var performingReverseGeocoding = false
  var lastGeoCodingError: Error?
  
  var timer: Timer?
  var managedObjectContext: NSManagedObjectContext!
  
  var logoVisible = false
  lazy var logoButton: UIButton = {
    let button = UIButton(type: .custom)
    button.setBackgroundImage(UIImage(named: "Logo"), for: .normal)
    button.sizeToFit()
    button.addTarget(self, action: #selector(getLocation), for: .touchUpInside)
    button.center.x = self.view.bounds.midX
    button.center.y = 220
    return button
  }()
  
  var soundID: SystemSoundID = 0
  
  
  // MARK: - Override Methods
  override func viewDidLoad() {
    super.viewDidLoad()
    updateLabels()
    loadSoundEffect("Sound.caf")
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.isNavigationBarHidden = true
  }
  
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    navigationController?.isNavigationBarHidden = false
  }
  
  
  // MARK: - CLLocationManagerDelegate
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    print("didFailWithError \(error)")
    
    if (error as NSError).code == CLError.locationUnknown.rawValue {
      return
    }
    
    lastLocationError = error
    stopLocationManager()
    updateLabels()
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    let newLocation = locations.last!
    print("didUpdateLocations \(newLocation)")
    
    // if time was over 5 seconds ago, then this is a cached result
    if newLocation.timestamp.timeIntervalSinceNow < -5 {
      return
    }
    
    if newLocation.horizontalAccuracy < 0 {
      return
    }
    
    // calculates difference between new reading and previous
    var distance = CLLocationDistance(Double.greatestFiniteMagnitude)
    if let location = location {
      distance = newLocation.distance(from: location)
    }
    
    if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy {
      lastLocationError = nil
      location = newLocation
      if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy {
        print("*** We're done!")
        stopLocationManager()
        
        if distance > 0 {
          performingReverseGeocoding = false
        }
      }
      updateLabels()
      
      if !performingReverseGeocoding {
        print("*** Going to geocode")
        
        performingReverseGeocoding = true
        
        geocoder.reverseGeocodeLocation(newLocation, completionHandler: {
          placemarks, error in
          self.lastGeoCodingError = error
          if error == nil, let p = placemarks, !p.isEmpty {
            if self.placemark == nil {
              print("FIRST TIME!")
              self.playSoundEffect()
            }
            self.placemark = p.last!
          } else {
            self.placemark = nil
          }
          self.performingReverseGeocoding = false
          self.updateLabels()
        })
    }
    } else if distance < 1 { // if coord from this reading not significantly different than previous reading...
      let timeInterval = newLocation.timestamp.timeIntervalSince(location!.timestamp)
      if timeInterval > 10 { // ...and it has been over 10 seconds since original reading
        print("*** Force done!")
        stopLocationManager()
        updateLabels()
      }
    }
  }
  
  
  // MARK: - Methods
  func showLocationServicesDeniedAlert() {
    let alert = UIAlertController(title: "Location Services Disabled", message: "Please enable location services for this app in Settings.", preferredStyle: .alert)
    
    let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
    
    alert.addAction(okAction)
    
    present(alert, animated: true, completion: nil)
  }
  
  func updateLabels() {
    if let location = location {
      latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
      longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
      tagButton.isHidden = false
      messageLabel.text = ""
      
      // display reverse geocoded address
      if let placemark = placemark {
        addressLabel.text = string(from: placemark)
      } else if performingReverseGeocoding {
        addressLabel.text = "Searching for Address..."
      } else if lastGeoCodingError != nil {
        addressLabel.text = "Error Finding Address"
      } else {
        addressLabel.text = "No Address Found"
      }
      latitudeTextLabel.isHidden = false
      longitudeTextLabel.isHidden = false
    } else {
      latitudeLabel.text = ""
      longitudeLabel.text = ""
      addressLabel.text = ""
      tagButton.isHidden = true
      
      let statusMessage: String
      if let error = lastLocationError as NSError? {
        if error.domain == kCLErrorDomain && error.code == CLError.denied.rawValue {
          statusMessage = "Location Services Disabled"
        } else {
          statusMessage = "Error Getting Location"
        }
      } else if !CLLocationManager.locationServicesEnabled() {
        statusMessage = "Location Services Disabled"
      } else if updatingLocation {
        statusMessage = "Searching..."
      } else {
        statusMessage = ""
        showLogoView()
      }
      messageLabel.text = statusMessage
      latitudeTextLabel.isHidden = true
      longitudeTextLabel.isHidden = true
    }
    configureGetButton()
  }
  
  func startLocationManager() {
    if CLLocationManager.locationServicesEnabled() {
      locationManager.delegate = self
      locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
      locationManager.startUpdatingLocation()
      updatingLocation = true
      timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(didTimeOut), userInfo: nil, repeats: false)
    }
  }
  
  func stopLocationManager() {
    if updatingLocation {
      locationManager.stopUpdatingLocation()
      locationManager.delegate = nil
      updatingLocation = false
      if let timer = timer {
        timer.invalidate()
      }
    }
  }
  
  func configureGetButton() {
    let spinnerTag = 1000
    
    if updatingLocation {
      getButton.setTitle("Stop", for: .normal)
      
      if view.viewWithTag(spinnerTag) == nil {
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .white)
        spinner.center = messageLabel.center
        spinner.center.y += spinner.bounds.size.height / 2 + 15
        spinner.startAnimating()
        spinner.tag = spinnerTag
        containerView.addSubview(spinner)
      }
    } else {
      getButton.setTitle("Get My Location", for: .normal)
      
      if let spinner = view.viewWithTag(spinnerTag) {
        spinner.removeFromSuperview()
      }
    }
  }
  
  func string(from placemark: CLPlacemark) -> String {
    var line1 = ""
    line1.add(text: placemark.subThoroughfare)
    line1.add(text: placemark.thoroughfare, separatedBy: " ")
    
    var line2 = ""
    line2.add(text: placemark.locality)
    line2.add(text: placemark.administrativeArea, separatedBy: " ")
    line2.add(text: placemark.postalCode, separatedBy: " ")
    
    line1.add(text: line2, separatedBy: "\n")
    return line1
  }
  
  @objc func didTimeOut() {
    print("*** Time out")
    if location == nil {
      stopLocationManager()
      lastLocationError = NSError(domain: "MyLocationsErrorDomain", code: 1, userInfo: nil)
      updateLabels()
    }
  }
  
  func showLogoView() {
    if !logoVisible {
      logoVisible = true
      containerView.isHidden = true
      view.addSubview(logoButton)
    }
  }
  
  func hideLogoView() {
    if !logoVisible { return }
    
    logoVisible = false
    containerView.isHidden = false
    containerView.center.x = view.bounds.size.width * 2
    containerView.center.y = 40 + containerView.bounds.size.height / 2
    
    let centerX = view.bounds.midX
    
    let panelMover = CABasicAnimation(keyPath: "position")
    panelMover.isRemovedOnCompletion = false
    panelMover.fillMode = kCAFillModeForwards
    panelMover.duration = 0.6
    panelMover.fromValue = NSValue(cgPoint: containerView.center)
    panelMover.toValue = NSValue(cgPoint: CGPoint(x: centerX, y: containerView.center.y))
    panelMover.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)
    panelMover.delegate = self
    containerView.layer.add(panelMover, forKey: "panelMover")
    
    let logoMover = CABasicAnimation(keyPath: "position")
    logoMover.isRemovedOnCompletion = false
    logoMover.fillMode = kCAFillModeForwards
    logoMover.duration = 0.5
    logoMover.fromValue = NSValue(cgPoint: logoButton.center)
    logoMover.toValue = NSValue(cgPoint: CGPoint(x: -centerX, y: logoButton.center.y))
    logoMover.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
    logoButton.layer.add(logoMover, forKey: "logoMover")
    
    let logoRotator = CABasicAnimation(keyPath: "transform.rotation.z")
    logoRotator.isRemovedOnCompletion = false
    logoRotator.fillMode = kCAFillModeForwards
    logoRotator.duration = 0.5
    logoRotator.fromValue = 0.0
    logoRotator.toValue = -2 * Double.pi
    logoRotator.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseIn)
    logoButton.layer.add(logoRotator, forKey: "logoRotator")
  }
  
  // MARK:- Animation Delegate Methods
  func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
    containerView.layer.removeAllAnimations()
    containerView.center.x = view.bounds.size.width / 2
    containerView.center.y = 40 + containerView.bounds.size.height / 2
    logoButton.layer.removeAllAnimations()
    logoButton.removeFromSuperview()
  }
  
  // MARK:= Sound effects
  func loadSoundEffect(_ name: String) {
    if let path = Bundle.main.path(forResource: name, ofType: nil) {
      let fileURL = URL(fileURLWithPath: path, isDirectory: false)
      let error = AudioServicesCreateSystemSoundID(fileURL as CFURL, &soundID)
      if error != kAudioServicesNoError {
        print("Error code \(error) loading sound: \(path)")
      }
    }
  }
  
  func unloadSoundEffect() {
    AudioServicesDisposeSystemSoundID(soundID)
    soundID = 0
  }
  
  func playSoundEffect() {
    AudioServicesPlaySystemSound(soundID)
  }
  
  // MARK:- Navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "TagLocation" {
      let controller = segue.destination as! LocationDetailsViewController
      controller.coordinate = location!.coordinate
      controller.placemark = placemark
      controller.managedObjectContext = managedObjectContext
    }
  }


}

