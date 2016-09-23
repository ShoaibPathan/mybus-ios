//
//  ViewController.swift
//  MyBus
//
//  Created by Marcos Vivar on 4/12/16.
//  Copyright © 2016 Spark Digital. All rights reserved.
//

import UIKit
import Mapbox
import RealmSwift
import MapKit
import MapboxDirections
import Polyline

class ViewController: UIViewController, MGLMapViewDelegate, UITableViewDelegate {

    @IBOutlet weak var busResultsTableView: UITableView!
    @IBOutlet weak var constraintTableViewHeight: NSLayoutConstraint!
    @IBOutlet var mapView: MyBusMapView!

    let busResultCellHeight: Int = 45
    let busResultTableHeightToHide: CGFloat = 0
    let markerOriginLabelText = "Origen"
    let markerDestinationLabelText = "Destino"
    let progressNotification = ProgressHUD()

    var origin: CLLocationCoordinate2D?
    var destination: CLLocationCoordinate2D?

    var bestMatches: [String] = []
    var busResultsDetail: [BusRouteResult] = []

    var currentRouteDisplayed: BusRouteResult?

    var searchViewProtocol: MapBusRoadDelegate?
    // MARK: - View Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        setBusResultsTableViewHeight(busResultTableHeightToHide)
        initMapboxView()
    }

    func initMapboxView() {
        mapView.initialize(self)

        // Setup offline pack notification handlers.
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.offlinePackProgressDidChange(_:)), name: MGLOfflinePackProgressChangedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.offlinePackDidReceiveError(_:)), name: MGLOfflinePackProgressChangedNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ViewController.offlinePackDidReceiveMaximumAllowedMapboxTiles(_:)), name: MGLOfflinePackProgressChangedNotification, object: nil)

        // Double tapping zooms the map, so ensure that can still happen
        let doubleTap = UITapGestureRecognizer(target: self, action: nil)
        doubleTap.numberOfTapsRequired = 2
        mapView.addGestureRecognizer(doubleTap)

        // Delay single tap recognition until it is clearly not a double
        let singleLongTap = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.handleSingleLongTap(_:)))
        singleLongTap.requireGestureRecognizerToFail(doubleTap)
        mapView.addGestureRecognizer(singleLongTap)
    }

    // MARK: - Tapping Methods

    @IBAction func locateUserButtonTap(sender: AnyObject) {
        let locationServiceAuth = CLLocationManager.authorizationStatus()
        if(locationServiceAuth == .AuthorizedAlways || locationServiceAuth == .AuthorizedWhenInUse) {
            self.mapView.showsUserLocation = true
            self.mapView.centerCoordinate = (self.mapView.userLocation!.location?.coordinate)!
            self.mapView.setZoomLevel(16, animated: false)
        } else {
            GenerateMessageAlert.generateAlertToSetting(self)
        }
    }

    func handleSingleLongTap(tap: UITapGestureRecognizer) {
        mapView.showsUserLocation = true
        // Convert tap location (CGPoint) to geographic coordinates (CLLocationCoordinate2D)
        self.destination = mapView.convertPoint(tap.locationInView(mapView), toCoordinateFromView: mapView)
        progressNotification.showLoadingNotification(self.view)
        CLGeocoder().reverseGeocodeLocation(CLLocation(latitude: self.destination!.latitude, longitude: self.destination!.longitude)) {
            placemarks, error in
            if let placemark = placemarks?.first {
                //sets attributes of annotation
                let annotation = MGLPointAnnotation()
                annotation.coordinate = CLLocationCoordinate2D(latitude: self.destination!.latitude, longitude: self.destination!.longitude)
                annotation.title = self.markerDestinationLabelText
                if let street = placemark.thoroughfare, let houseNumber = placemark.subThoroughfare {
                    annotation.subtitle = "\(street as String) \(houseNumber as String)"
                }
                //add annotation in the map
                self.mapView.addAnnotation(annotation)
                self.mapView.setCenterCoordinate(annotation.coordinate, zoomLevel: 14, animated: false)
                self.mapView.selectAnnotation(annotation, animated: false)
            }
            self.progressNotification.stopLoadingNotification(self.view)
        }
    }

    func mapView(mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }

    /**
        This method sets the button of the annotation
    */
    func mapView(mapView: MGLMapView, rightCalloutAccessoryViewForAnnotation annotation: MGLAnnotation) -> UIView? {
        let annotationTitle = annotation.title!! as String
        // Only display button when marker is with Destino title
        if annotationTitle == markerDestinationLabelText {
            let button = UIButton(type: .DetailDisclosure)
            button.setImage(UIImage(named: "tabbar_route_fill"), forState: UIControlState.Normal)
            return button
        }
        return nil
    }

    /**
        This method makes the search when the button is pressed on the annotation
    */
    func mapView(mapView: MGLMapView, annotation: MGLAnnotation, calloutAccessoryControlTapped control: UIControl) {
        // Hide the callout view.
        mapView.deselectAnnotation(annotation, animated: false)
        progressNotification.showLoadingNotification(self.view)
        //Make the search
        let locationServiceAuth = CLLocationManager.authorizationStatus()
        //If origin location is diferent nil
        if (locationServiceAuth == .AuthorizedAlways || locationServiceAuth == .AuthorizedWhenInUse) {
            if let originAddress = self.mapView.userLocation?.coordinate {
                self.mapView.addAnnotation(annotation)
                SearchManager.sharedInstance.search(originAddress, destination:self.destination!, completionHandler: {
                    (busRouteResult, error) in
                    self.progressNotification.stopLoadingNotification(self.view)
                    if let results = busRouteResult {
                        self.addBusLinesResults(results)
                    }
                })
            } else {
                self.mapView.showsUserLocation = true
                self.progressNotification.stopLoadingNotification(self.view)
            }
        } else {
            self.progressNotification.stopLoadingNotification(self.view)
            GenerateMessageAlert.generateAlertToSetting(self)
        }
    }
    // MARK: - Private Methods

    func dismissSearchController(controller: UIViewController) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }

    // MARK: - Memory Management Methods

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func mapViewDidFinishLoadingMap(mapView: MGLMapView) {
        if MGLOfflineStorage.sharedOfflineStorage().packs?.count == 0 {
            startOfflinePackDownload()
        }
    }

    func mapView(mapView: MGLMapView, imageForAnnotation annotation: MGLAnnotation) -> MGLAnnotationImage? {

        if let myBusMarker = annotation as? MyBusMarker {
            return myBusMarker.markerImage
        }
        
        let annotationTitle = annotation.title!! as String
        let imageName = "marker"+annotation.title!! as String
        
        
        var annotationImage = mapView.dequeueReusableAnnotationImageWithIdentifier(annotationTitle)
        if annotationImage == nil {
            switch annotationTitle {
            case markerOriginLabelText:
                annotationImage =  self.mapView.getMarkerImage(imageName, annotationTitle: annotationTitle)
            case markerDestinationLabelText:
                annotationImage =  self.mapView.getMarkerImage(imageName, annotationTitle: annotationTitle)
            case MyBusTitle.StopOriginTitle.rawValue:
                annotationImage =  self.mapView.getMarkerImage("stopOrigen", annotationTitle: annotationTitle)
            case MyBusTitle.StopDestinationTitle.rawValue:
                annotationImage =  self.mapView.getMarkerImage("stopDestino", annotationTitle: annotationTitle)
            case ~/MyBusTitle.SameStartEndCompleteBusRoute.rawValue:
                annotationImage =  self.mapView.getMarkerImage("map_from_to_route", annotationTitle: annotationTitle)
            case ~/MyBusTitle.StartCompleteBusRoute.rawValue:
                annotationImage =  self.mapView.getMarkerImage("stopOrigen", annotationTitle: annotationTitle)
            case ~/MyBusTitle.EndCompleteBusRoute.rawValue:
                annotationImage =  self.mapView.getMarkerImage("stopDestino", annotationTitle: annotationTitle)
                annotationImage =  self.mapView.getMarkerImage("stopDestino", annotationTitle: annotationTitle)
            case ~/"carga":
                annotationImage =  self.mapView.getMarkerImage("map_charge", annotationTitle: annotationTitle)
            default:
                break
            }
        }
        return annotationImage
    }

    func mapView(mapView: MGLMapView, alphaForShapeAnnotation annotation: MGLShape) -> CGFloat {
        // Set the alpha for all shape annotations to 1 (full opacity)
        return 1
    }

    func mapView(mapView: MGLMapView, lineWidthForPolylineAnnotation annotation: MGLPolyline) -> CGFloat {
        // Set the line width for polyline annotations
        return 2.0
    }

    func mapView(mapView: MGLMapView, strokeColorForShapeAnnotation annotation: MGLShape) -> UIColor {
        // Give our polyline a unique color by checking for its `title` property
        let isWalkingPathPolyline = annotation.title == "Caminando" && annotation is MGLPolyline
        if isWalkingPathPolyline {
            // Mapbox cyan
            return UIColor(red: 59/255, green:178/255, blue:208/255, alpha:1)
        } else {
            var idBusIndex: Int?
            if annotation.subtitle?.characters.count == 0, let key = currentRouteDisplayed?.busRoutes.first?.idBusLine {
                idBusIndex = key
            } else if let subtitle = annotation.subtitle {
                idBusIndex = Int(subtitle)!
            }

            if var idBusIndex = idBusIndex {
                //Hacking the index
                if idBusIndex < 10 {
                    idBusIndex = idBusIndex - 1
                } else if idBusIndex < 41 {
                    idBusIndex = idBusIndex - 2
                } else {
                    idBusIndex = idBusIndex - 3
                }

                if let path = NSBundle.mainBundle().pathForResource("BusColors", ofType: "plist"), dict = (NSArray(contentsOfFile: path))!.objectAtIndex(idBusIndex) as? [String: String] {
                    if let color = dict["color"] {
                        return UIColor(hexString: color)
                    } else {
                        return UIColor.grayColor()
                    }
                }
            }

            if let title =  annotation.title {
                switch title {
                case "Going":
                    return UIColor(hexString: "0288D1")
                case "Return":
                    return UIColor(hexString: "EE236F")
                default:
                    break
                }
            }
            return UIColor.grayColor()
        }
    }

    func mapView(mapView: MGLMapView, didFailToLocateUserWithError error: NSError) {
        print("error locating user: \(error.localizedDescription)")
        GenerateMessageAlert.generateAlertToSetting(self)
    }

    // MARK: - Mapview bus roads manipulation Methods
    func addRechargePoints(rechargePoints: [RechargePoint]) -> Void {
        self.mapView.addRechargePoints(rechargePoints)
    }
    
    func clearRechargePoints(){
        self.mapView.clearRechargePointAnnotations()       
    }

    func displayCompleteBusRoute(route: CompleteBusRoute) -> Void {
        progressNotification.showLoadingNotification(self.view)
        self.mapView.displayCompleteBusRoute(route)
        self.progressNotification.stopLoadingNotification(self.view)
        self.mapView.fitToAnnotationsInMap()
    }

    func addBusRoad(roadResult: RoadResult) {
        progressNotification.showLoadingNotification(self.view)
        self.mapView.addBusRoad(roadResult)
        
        // First we render polylines on Map then we remove loading notification
        self.progressNotification.stopLoadingNotification(self.view)
        self.mapView.fitToAnnotationsInMap()
    }

    func addBusLinesResults(searchResults: BusSearchResult) {
        progressNotification.showLoadingNotification(self.view)
        
        self.mapView.addOriginPosition(searchResults.origin.getLatLong(), address: searchResults.origin.address)
        self.mapView.addDestinationPosition(searchResults.destination.getLatLong(), address: searchResults.destination.address)
        
        self.bestMatches = searchResults.stringifyBusRoutes()
        self.busResultsDetail = searchResults.busRouteOptions
        progressNotification.stopLoadingNotification(self.view)
        getRoadForSelectedResult(self.busResultsDetail.first)
        self.busResultsTableView.reloadData()
        self.constraintTableViewHeight.constant = CGFloat(busResultCellHeight)
        self.busResultsTableView.layoutIfNeeded()
        //Scroll to first result preventing keep previous row selected by user
        self.busResultsTableView.selectRowAtIndexPath(NSIndexPath(forRow: 0, inSection: 0), animated: true, scrollPosition: .Middle)
    }

    func addOriginPosition(origin: CLLocationCoordinate2D, address: String) {
        self.mapView.addOriginPosition(origin, address: address)
    }

    func addDestinationPosition(destination: CLLocationCoordinate2D, address: String) {
        self.mapView.addDestinationPosition(destination, address: address)
    }

    func clearRouteAnnotations(){
        self.mapView.clearExistingBusRouteAnnotations()
    }
    
    // MARK: - UIPopoverPresentationControllerDelegate Methods

    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .None
    }

    func prepareForPopoverPresentation(popoverPresentationController: UIPopoverPresentationController) {
        print("prepare for presentation")
    }

    func popoverPresentationControllerDidDismissPopover(popoverPresentationController: UIPopoverPresentationController) {
        print("did dismiss")
    }

    func popoverPresentationControllerShouldDismissPopover(popoverPresentationController: UIPopoverPresentationController) -> Bool {
        print("should dismiss")
        return true
    }

    // MARK: - Pack Download

    func startOfflinePackDownload() {
        let region = MGLTilePyramidOfflineRegion(styleURL: mapView.styleURL, bounds: mapView.visibleCoordinateBounds, fromZoomLevel: mapView.minZoomLevel, toZoomLevel: mapView.maxZoomLevel)
        let userInfo = ["name": "OfflineMap"]
        let context = NSKeyedArchiver.archivedDataWithRootObject(userInfo)

        MGLOfflineStorage.sharedOfflineStorage().addPackForRegion(region, withContext: context) { (pack, error) in
            guard error == nil else {
                print("Error: \(error?.localizedFailureReason)")
                return
            }

            pack!.resume()
        }
    }

    // MARK: - MGLOfflinePack Notification Handlers

    func offlinePackProgressDidChange(notification: NSNotification) {
        if let pack = notification.object as? MGLOfflinePack,
            userInfo = NSKeyedUnarchiver.unarchiveObjectWithData(pack.context) as? [String: String] {
            let progress = pack.progress
            let completedResources = progress.countOfResourcesCompleted
            let expectedResources = progress.countOfResourcesExpected
            let progressPercentage = Float(completedResources) / Float(expectedResources)

            if completedResources == expectedResources {
                let byteCount = NSByteCountFormatter.stringFromByteCount(Int64(pack.progress.countOfBytesCompleted), countStyle: NSByteCountFormatterCountStyle.Memory)
                print("Offline pack “\(userInfo["name"])” completed: \(byteCount), \(completedResources) resources")
            } else {
                print("Offline pack “\(userInfo["name"])” has \(completedResources) of \(expectedResources) resources — \(progressPercentage * 100)%.")
            }
        }
    }

    func offlinePackDidReceiveError(notification: NSNotification) {
        if let pack = notification.object as? MGLOfflinePack,
            userInfo = NSKeyedUnarchiver.unarchiveObjectWithData(pack.context) as? [String: String],
            error = notification.userInfo?[MGLOfflinePackErrorUserInfoKey] as? NSError {
            print("Offline pack “\(userInfo["name"])” received error: \(error.localizedFailureReason)")
        }
    }

    func offlinePackDidReceiveMaximumAllowedMapboxTiles(notification: NSNotification) {
        if let pack = notification.object as? MGLOfflinePack,
            userInfo = NSKeyedUnarchiver.unarchiveObjectWithData(pack.context) as? [String: String],
            maximumCount = notification.userInfo?[MGLOfflinePackMaximumCountUserInfoKey]?.unsignedLongLongValue {
            print("Offline pack “\(userInfo["name"])” reached limit of \(maximumCount) tiles.")
        }
    }

    // MARK: - UITableViewDataSource Methods

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("BusIdentifier", forIndexPath: indexPath) as UITableViewCell
        cell.textLabel?.text = self.bestMatches[indexPath.row]
        return cell
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bestMatches.count
    }

    // MARK: - UITableViewDelegate Methods

    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        setBusResultsTableViewHeight(CGFloat(busResultCellHeight))
        // Lisandro added the following line because if table expanded is more than 50% of view height zoom does not work as expected
        self.mapView.layoutIfNeeded()
        let selectedRoute = busResultsDetail[indexPath.row]
        if let currentRoute = self.currentRouteDisplayed {
            if currentRoute != selectedRoute {
                progressNotification.showLoadingNotification(self.view)
                getRoadForSelectedResult(selectedRoute)
            } else {
                self.mapView.fitToAnnotationsInMap()
            }
        }
        self.busResultsTableView.scrollToNearestSelectedRowAtScrollPosition(.Middle, animated: false)
    }

    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        setBusResultsTableViewHeight(CGFloat(busResultCellHeight * self.bestMatches.count))
    }

    func setBusResultsTableViewHeight(height: CGFloat) {
        self.constraintTableViewHeight.constant = CGFloat(height)
        self.busResultsTableView.layoutIfNeeded()
    }

    func getRoadForSelectedResult(routeSelectedResult: BusRouteResult?) -> Void {
        progressNotification.showLoadingNotification(self.view)
        if let route = routeSelectedResult {
            self.currentRouteDisplayed = route
            SearchManager.sharedInstance.getRoad(route) {
                road, error in
                self.progressNotification.stopLoadingNotification(self.view)
                if let routeRoad = road {
                    self.addBusRoad(routeRoad)
                } else {
                    GenerateMessageAlert.generateAlert(self, title: "Tuvimos un problema 😿", message: "No pudimos resolver el detalle de la opción seleccionada")
                }
            }
        }
    }

}

prefix operator ~/ {}

prefix func ~/ (pattern: String) -> NSRegularExpression {
    return try! NSRegularExpression(pattern: pattern, options: .CaseInsensitive)
}

func ~= (pattern: NSRegularExpression, str: String) -> Bool {
    return pattern.numberOfMatchesInString(str, options: [], range: NSRange(location: 0, length: str.characters.count)) > 0
}
