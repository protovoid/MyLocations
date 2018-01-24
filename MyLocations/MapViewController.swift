//
//  MapViewController.swift
//  MyLocations
//
//  Created by Chad on 1/20/18.
//  Copyright © 2018 Chad Williams. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {
  @IBOutlet weak var mapView: MKMapView!
  
  var managedObjectContext: NSManagedObjectContext! {
    didSet {
      NotificationCenter.default.addObserver(forName: Notification.Name.NSManagedObjectContextObjectsDidChange, object: managedObjectContext, queue: OperationQueue.main) { notification in
        if self.isViewLoaded {
          self.updateLocations()
        }
      }
    }
  }
  
  var locations = [Location]()
  
  
  // MARK:- Actions
  @IBAction func showUser() {
    let region = MKCoordinateRegionMakeWithDistance(mapView.userLocation.coordinate, 1000, 1000)
    mapView.setRegion(mapView.regionThatFits(region), animated: true)
  }
  
  @IBAction func showLocations() {
    let theRegion = region(for: locations)
    mapView.setRegion(theRegion, animated: true)
  }
  
  
  // MARK:- Private methods
  func updateLocations() {
    mapView.removeAnnotations(locations)
    
    let entity = Location.entity()
    
    let fetchRequest = NSFetchRequest<Location>()
    fetchRequest.entity = entity
    
    locations = try! managedObjectContext.fetch(fetchRequest)
    mapView.addAnnotations(locations)
  }
  
  func region(for annotations: [MKAnnotation]) -> MKCoordinateRegion {
    let region: MKCoordinateRegion
    
    switch annotations.count {
      // center map on user's current position if no annotations
    case 0:
      region = MKCoordinateRegionMakeWithDistance(mapView.userLocation.coordinate, 1000, 1000)
      
      // center map on annotation if only 1 exists
    case 1:
      let annotation = annotations[annotations.count - 1]
      region = MKCoordinateRegionMakeWithDistance(annotation.coordinate, 1000, 1000)
      
      // fit all annotations onto map
    default:
      var topLeft = CLLocationCoordinate2D(latitude: -90, longitude: 180)
      var bottomRight = CLLocationCoordinate2D(latitude: 90, longitude: -180)
      
      for annotation in annotations {
        topLeft.latitude = max(topLeft.latitude, annotation.coordinate.latitude)
        topLeft.longitude = min(topLeft.longitude, annotation.coordinate.longitude)
        bottomRight.latitude = min(bottomRight.latitude, annotation.coordinate.latitude)
        bottomRight.longitude = max(bottomRight.longitude, annotation.coordinate.longitude)
      }
      
      let center = CLLocationCoordinate2D(latitude: topLeft.latitude - (topLeft.latitude - bottomRight.latitude), longitude: topLeft.longitude - (topLeft.longitude - bottomRight.longitude))
      
      let extraSpace = 1.1
      let span = MKCoordinateSpan(latitudeDelta: abs(topLeft.latitude - bottomRight.latitude) * extraSpace, longitudeDelta: abs(topLeft.longitude - bottomRight.longitude) * extraSpace)
      
      region = MKCoordinateRegion(center: center, span: span)
    }
    return mapView.regionThatFits(region)
  }
  
  @objc func showLocationDetails(_ sender: UIButton) {
    performSegue(withIdentifier: "EditLocation", sender: sender)
  }
  
  
  // MARK:- Navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "EditLocation" {
      let controller = segue.destination as! LocationDetailsViewController
      controller.managedObjectContext = managedObjectContext
      
      let button = sender as! UIButton
      let location = locations[button.tag]
      controller.locationToEdit = location
    }
  }
  
  
  // MARK:- Overrides
  override func viewDidLoad() {
    super.viewDidLoad()
    updateLocations()
    
    if !locations.isEmpty {
      showLocations()
    }
  }
}


extension MapViewController: MKMapViewDelegate {
  func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    guard annotation is Location else {
      return nil
    }
    let identifier = "Location"
    var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
    
    if annotationView == nil {
      let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
      
      pinView.isEnabled = true
      pinView.canShowCallout = true
      pinView.animatesDrop = false
      pinView.pinTintColor = UIColor(red: 0.00, green: 0.82, blue: 0.4, alpha: 1)
      
      let rightButton = UIButton(type: .detailDisclosure)
      rightButton.addTarget(self, action: #selector(showLocationDetails), for: .touchUpInside)
      pinView.rightCalloutAccessoryView = rightButton
      
      annotationView = pinView
    }
    
    if let annotationView = annotationView {
      annotationView.annotation = annotation
      
      let button = annotationView.rightCalloutAccessoryView as! UIButton
      if let index = locations.index(of: annotation as! Location) {
        button.tag = index
      }
    }
    return annotationView
  }
}