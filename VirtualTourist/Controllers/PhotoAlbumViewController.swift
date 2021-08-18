//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Jongmin Lee on 9/23/20.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController {

    @IBOutlet weak var noImageLabel: UILabel!
    var pageNum = 1
    var urlImage = [PhotoResponse]()
    
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var mapView: MKMapView!
    
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Photos>!
    var pin: Pin!
    
    func setUpFetchedResultsController(){
        let fetchRequest:NSFetchRequest<Photos> = Photos.fetchRequest()
        let predicate = NSPredicate(format: "photos == %@", pin)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = []
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpFetchedResultsController()
        checkAlbumExists()
        initialSetting()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        setUpFetchedResultsController()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        fetchedResultsController = nil
    }

    func initialSetting(){
        mapView.delegate = self
        photoCollectionView.delegate = self
        photoCollectionView.dataSource = self
        makeAnnotation()
    }
        
    func makeAnnotation(){
        let annotation = MKPointAnnotation()
        annotation.coordinate = CLLocationCoordinate2D(latitude: pin.lat, longitude: pin.lon)
        mapView.addAnnotation(annotation)
        
        let coordinateRegion = MKCoordinateRegion(center: annotation.coordinate, latitudinalMeters: 2500, longitudinalMeters: 2500)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func checkAlbumExists(){
        if fetchedResultsController.fetchedObjects!.count == 0 {
            FlickerClient.search(lat: String(pin.lat), lon: String(pin.lon), pageNum: pageNum, completion: searchResponseHanlder(response:error:))
            pageNum += 1
            photoCollectionView.reloadData()
        }
    }
        
    @IBAction func newCollectionButtonPressed(_ sender: Any) {
        clearAlbum()
        FlickerClient.search(lat: String(pin.lat), lon: String(pin.lon), pageNum: pageNum, completion: searchResponseHanlder(response:error:))
        pageNum += 1
        photoCollectionView.reloadData()
    }
    
    func clearAlbum(){
        if fetchedResultsController.fetchedObjects!.count > 0 {
            for photo in fetchedResultsController.fetchedObjects! {
                dataController.viewContext.delete(photo)
                try? dataController.viewContext.save()
            }
            photoCollectionView.reloadData()
        }
    }

    func searchResponseHanlder(response: [PhotoResponse], error: Error?){
        noImageLabel.isHidden = true
        if error != nil {
            print("Error in search response in PhotoAlbumView")
        } else {
            if response.count == 0{
                noImageLabel.isHidden = false
            } else {
                dataController.backGroundContext.perform {
                    PhotoData.sharedInstance.saveImage(context: self.dataController.viewContext, photos: response, parentData: self.pin)
                }
            }
        }
    }
    
}

//MARK:- Mapview delegate
extension PhotoAlbumViewController: MKMapViewDelegate {
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
}


//MARK:- Collectionview Delegate, DataSource
extension PhotoAlbumViewController: UICollectionViewDelegate, UICollectionViewDataSource {
        
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoCollectionViewCell
        let photo = fetchedResultsController.object(at: indexPath)
        cell.photoImage.image = UIImage(data: photo.photo!)
        cell.photoImage.frame.size = cell.frame.size
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let photoToDelete = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(photoToDelete)
        try? dataController.viewContext.save()
        photoCollectionView.reloadData()
    }

}

// MARK:- Collectionview flow layout
extension PhotoAlbumViewController: UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let dimension = (view.frame.size.width - 5)/3.0
        return CGSize(width: dimension, height: dimension)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 2.0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 2.0
    }
}


//MARK:- NSFetchedResultsController delegate
extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            photoCollectionView.reloadData()
            break
        case .delete:
            photoCollectionView.deleteItems(at: [indexPath!])
            break
        case .update:
            photoCollectionView.reloadItems(at: [indexPath!])
        default:
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let indexSet = IndexSet(integer: sectionIndex)
        switch type {
        case .insert:
            photoCollectionView.insertSections(indexSet)
        case .delete:
            photoCollectionView.deleteSections(indexSet)
        default:
            ()
        }
    }
    
}
