//
//  ViewController.swift
//  MapboxTesting
//
//  Created by Rustam G on 16.11.2020.
//

import Mapbox
import UIKit

private let defaultPlane = CLLocationCoordinate2D(latitude: 39.57426600071248, longitude: -105.01620233058928)
private let defaultTrackStart = CLLocationCoordinate2D(latitude: 39.55934984624357, longitude: -105.03045558929443)
private let defaultTrackEnd = CLLocationCoordinate2D(latitude: 39.57426600071248, longitude: -105.01620233058928)

class ViewController: UIViewController, MGLMapViewDelegate {

    @IBOutlet weak var sidebarContainer: UIView!
    @IBOutlet weak var mapContainer: UIView!

    @IBOutlet weak var planeLatitudeField: UITextField!
    @IBOutlet weak var planeLongitudeField: UITextField!

    @IBOutlet weak var trackStartLatitudeField: UITextField!
    @IBOutlet weak var trackStartLongitudeField: UITextField!

    @IBOutlet weak var trackEndLatitudeField: UITextField!
    @IBOutlet weak var trackEndLongitudeField: UITextField!

    @IBOutlet weak var trackLengthField: UITextField!

    @IBOutlet weak var trackAngleRadField: UITextField!
    @IBOutlet weak var trackAngleDegreesField: UITextField!

    @IBOutlet weak var planeXField: UITextField!
    @IBOutlet weak var planeYField: UITextField!
    @IBOutlet weak var crossTrackField: UITextField!
    @IBOutlet weak var answerLabel: UILabel!

    private weak var mapView: MGLMapView!

    private let plane = PointAnnotation(.plane, coordinate: defaultPlane)
    private let trackStart = PointAnnotation(.trackStart, coordinate: defaultTrackStart)
    private let trackEnd = PointAnnotation(.trackEnd, coordinate: defaultTrackEnd)

    override func viewDidLoad() {
        super.viewDidLoad()

        let url = URL(string: "mapbox://styles/mapbox/streets-v11")
        let mapView = MGLMapView(frame: view.bounds, styleURL: url)
        self.mapView = mapView

        mapView.setCenter(defaultTrackStart, zoomLevel: 12, animated: false)
        mapView.delegate = self

        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapContainer.addSubview(mapView)
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: mapView.superview!.topAnchor),
            mapView.trailingAnchor.constraint(equalTo: mapView.superview!.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: mapView.superview!.bottomAnchor),
            mapView.leadingAnchor.constraint(equalTo: mapView.superview!.leadingAnchor)
        ])

        self.updateCoordinateFields(annotation: plane)
        self.updateCoordinateFields(annotation: trackStart)
        self.updateCoordinateFields(annotation: trackEnd)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            mapView.addAnnotations([self.plane, self.trackStart, self.trackEnd])
            self.updateShapes()
            self.calculate()
        }
    }

    private func updateShapes() {

        guard let style = mapView.style else {
            return
        }

        var coordinates = [trackStart.coordinate, trackEnd.coordinate]

        let shape = MGLPolylineFeature(coordinates: &coordinates, count: UInt(coordinates.count))

        let id = "line"

        let source: MGLShapeSource

        if let existingSource = style.source(withIdentifier: id) as? MGLShapeSource {
            existingSource.shape = shape
            source = existingSource
        } else {
            source = MGLShapeSource(identifier: id, shape: shape)
            style.addSource(source)
        }

        if style.layer(withIdentifier: id) == nil {
            style.addLayer(MGLLineStyleLayer(identifier: id, source: source))
        }
    }

    private func calculate() {

        let answer = plane.coordinate.getLocationRelativeToTrack(startingAtPoint: trackStart.coordinate, endPoint: trackEnd.coordinate)

        let info = answer.info
        trackLengthField.text = info.trackLength.format() + "m"
        trackAngleRadField.text = info.trackAngleRad.format()
        trackAngleDegreesField.text = "\(info.trackAngleDegrees)°"
        answerLabel.text = answer.answer
        crossTrackField.text = info.crossTrackMeters.format() + "m"
    }

    // MARK: - MGLMapViewDelegate methods

    func mapView(_ mapView: MGLMapView, didAdd annotationViews: [MGLAnnotationView]) {
        debugPrint("Annotation views added: '\(annotationViews)")
    }

    func mapView(_ mapView: MGLMapView, viewFor annotation: MGLAnnotation) -> MGLAnnotationView? {
        // This example is only concerned with point annotations.
        guard let annotation = annotation as? PointAnnotation else {
            return nil
        }

        let reuseIdentifier = annotation.type.rawValue

        let view: PointAnnotationView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) as? PointAnnotationView
            ?? PointAnnotationView(reuseIdentifier: reuseIdentifier)

        view.name = annotation.type.rawValue
        view.bubbleColor = .blue
        
        view.coordinateUpdated = { [weak self] coordinate in
            self?.updateCoordinateFields(annotation: annotation)
            self?.updateShapes()
            self?.calculate()
        }

        return view
    }

    func mapView(_ mapView: MGLMapView, annotationCanShowCallout annotation: MGLAnnotation) -> Bool {
        return true
    }

    private func updateCoordinateFields(annotation: PointAnnotation) {

        let latitudeField: UITextField
        let longitudeField: UITextField

        switch annotation.type {
        case .plane:
            latitudeField = planeLatitudeField
            longitudeField = planeLongitudeField
        case .trackStart:
            latitudeField = trackStartLatitudeField
            longitudeField = trackStartLongitudeField
        case .trackEnd:
            latitudeField = trackEndLatitudeField
            longitudeField = trackEndLongitudeField
        }

        latitudeField.text = annotation.coordinate.latitude.format()
        longitudeField.text = annotation.coordinate.longitude.format()
    }
}

extension Double {

    func format() -> String {
        let formatter = NumberFormatter()
        let number = NSNumber(value: self)
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 7 //maximum digits in Double after dot (maximum precision)
        formatter.decimalSeparator = "."
        return String(formatter.string(from: number) ?? "")
    }
}

private struct TestInput {

    let plane: CLLocationCoordinate2D
    let trackStart: CLLocationCoordinate2D
    let trackEnd: CLLocationCoordinate2D

    /// use https://geojson.io/ to preview the data
    func toGeoJSON() -> String {

        return """
               {
                 "type": "FeatureCollection",
                 "features": [
                   {
                     "type": "Feature",
                     "properties": {
                       "stroke": "#555555",
                       "stroke-width": 2.1,
                       "stroke-opacity": 1
                     },
                     "geometry": {
                       "type": "LineString",
                       "coordinates": [
                         [
                           \(trackStart.longitude),
                           \(trackStart.latitude)
                         ],
                         [
                           \(trackEnd.longitude),
                           \(trackEnd.latitude)
                         ]
                       ]
                     }
                   },
                   {
                     "type": "Feature",
                     "properties": {
                       "marker-color": "#7e7e7e",
                       "marker-size": "medium",
                       "marker-symbol": "airport"
                     },
                     "geometry": {
                       "type": "Point",
                       "coordinates": [
                         \(plane.longitude),
                         \(plane.latitude)
                       ]
                     }
                   },
                   {
                     "type": "Feature",
                     "properties": {
                       "marker-color": "#7e7e7e",
                       "marker-size": "medium",
                       "marker-symbol": "triangle-stroked",
                       "it_is_end": ""
                     },
                     "geometry": {
                       "type": "Point",
                       "coordinates": [
                           \(trackEnd.longitude),
                           \(trackEnd.latitude)
                       ]
                     }
                   }
                 ]
               }
               """
    }
}



enum LocationRelativeToTrack {

    case left(_ info: Info)
    case right(_ info: Info)
    case onLine(_ info: Info)

    var answer: String {
        switch self {
        case .left:
            return "left"
        case .right:
            return "right"
        case .onLine:
            return "on line"
        }
    }
    var info: Info {
        switch self {
        case let .left(info):
            return info
        case let .right(info):
            return info
        case let .onLine(info):
            return info
        }
    }

    struct Info {

        var trackLength: Double
        var trackAngleRad: Double
        var trackAngleDegrees: Double
        var crossTrackMeters: Double
    }
}
