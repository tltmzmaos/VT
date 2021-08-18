//
//  TravelLocationsMapViewController.swift
//  VirtualTourist
//
//  Created by Jongmin Lee on 9/22/20.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    
    var location: CLLocationCoordinate2D!
    var pin: Pin!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var dataController: DataController!
    var pins:[Pin] = []

    
    var pinFetchedResultsController: NSFetchedResultsController<Pin>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupPinFetchedResultsController()
        mapViewSetting()
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupPinFetchedResultsController()
    }
    
    func setupPinFetchedResultsController(){
        dataController = appDelegate.dataController
        let fetchRequest: NSFetchRequest<Pin> = Pin.fetchRequest()
        fetchRequest.sortDescriptors = []
        
        pinFetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        pinFetchedResultsController.delegate = self
        do {
            try pinFetchedResultsController.performFetch()
        } catch {
            print("error in fetch pins")
        }
        pins = pinFetchedResultsController.fetchedObjects!
        getAllAnnotations()
    }
    
    func getAllAnnotations(){
        for i in pinFetchedResultsController.fetchedObjects! {
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: i.lat, longitude: i.lon)
            mapView.addAnnotation(annotation)
        }
    }
            
    func mapViewSetting(){
        mapView.delegate = self
        
        loadMapLocationData()
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(mapTouchHandler(gesture:)))
        mapView.addGestureRecognizer(gestureRecognizer)
    }
    
    @objc func mapTouchHandler(gesture: UILongPressGestureRecognizer){
        if gesture.state == .began{
            let location = gesture.location(in: mapView)
            let coordinate = mapView.convert(location, toCoordinateFrom: mapView)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
            
            let newLocation = Pin(context: dataController.viewContext)
            newLocation.lat = coordinate.latitude
            newLocation.lon = coordinate.longitude
            try? dataController.viewContext.save()
            pins.append(newLocation)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "locationDetail" {
            let destinationVC = segue.destination as! PhotoAlbumViewController
            destinationVC.dataController = dataController
            destinationVC.pin = pin
        }
    }
    
    func searchResponseHandler(response:[PhotoResponse], error: Error?){
        if error != nil{
            return
        } else {
            PhotoData.sharedInstance.saveImage(context: dataController.viewContext, photos: response, parentData: pin)
        }
    }
    
    func findLocationObject(lat: Double, lon: Double) -> Pin? {
        for location in pins{
            if location.lat == lat && location.lon == lon{
                return location
            }
        }
        return nil
    }
    
    func saveMapLocationData(){
        let regionInfo = mapView.region
        UserDefaults.standard.setValue(regionInfo.center.latitude, forKey: "mapLat")
        UserDefaults.standard.setValue(regionInfo.center.longitude, forKey: "mapLon")
        UserDefaults.standard.setValue(regionInfo.span.latitudeDelta, forKey: "spanLat")
        UserDefaults.standard.setValue(regionInfo.span.longitudeDelta, forKey: "spanLon")
        UserDefaults.standard.setValue(true, forKey: "hasMapData")
    }
    
    func loadMapLocationData(){
        if UserDefaults.standard.bool(forKey: "hasMapData") {
            let center = CLLocationCoordinate2D(latitude: UserDefaults.standard.double(forKey: "mapLat"), longitude: UserDefaults.standard.double(forKey: "mapLon"))
            let span = MKCoordinateSpan(latitudeDelta: UserDefaults.standard.double(forKey: "spanLat"), longitudeDelta: UserDefaults.standard.double(forKey: "spanLon"))
            mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: true)
        }
    }
}

//MARK:- Mapview delegate
extension TravelLocationsMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "locations"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = false
        } else {
            annotationView?.annotation = annotation
        }
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        location = view.annotation?.coordinate
        pin = findLocationObject(lat: location.latitude, lon: location.longitude)
        performSegue(withIdentifier: "locationDetail", sender: self)
    }
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        saveMapLocationData()
    }
}

//MARK:- NSFetchedResultController delegate
extension TravelLocationsMapViewController: NSFetchedResultsControllerDelegate {
    
}
