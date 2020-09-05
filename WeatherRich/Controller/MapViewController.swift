import UIKit
import CoreLocation
import MapKit

class MapViewController: UIViewController {
    @IBOutlet var mapView: MKMapView!

    private let locationManager = CLLocationManager()
    private var locationItem: UIBarButtonItem?
    private var requestSent = false

    override func viewDidLoad() {
        super.viewDidLoad()

        let barbuttonItem = MKUserTrackingBarButtonItem(mapView: mapView)
        self.navigationItem.leftBarButtonItem = barbuttonItem
        self.locationItem = barbuttonItem

        setLocateMe(visible: true)
        mapView.delegate = self
        locationManager.delegate = self
        getUserLocation()

        // Keeping double-tap will conflict with the map's default gesture; keeping the long press gesture instead.
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressDetected(gestureRecognizer:)))
        mapView.addGestureRecognizer(longPressGesture)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        requestSent = false
    }

    private func getUserLocation() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            self.locationItem?.isEnabled = true
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
          locationManager.requestWhenInUseAuthorization()
            break
        case .authorizedAlways:
            break
        @unknown default:
          break
      }
    }

    private func setLocateMe(visible: Bool) {
        if let locationItem = self.locationItem, visible == true {
            navigationItem.leftBarButtonItem = locationItem
        } else {
            navigationItem.leftBarButtonItem = nil
        }
    }

    @objc private func longPressDetected(gestureRecognizer: UIGestureRecognizer) {
        guard gestureRecognizer.state == .began else {
            return
        }

        let point = gestureRecognizer.location(in: view)
        let coordinate = mapView.convert(point, toCoordinateFrom: view)
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        fetchWeatherData(location: location)
    }

    private func fetchWeatherData(location: CLLocation) {
        guard requestSent == false else {
            return
        }
        requestSent = true
        if let weatherDetailView = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WeatherDetailViewController") as? WeatherDetailViewController {
            weatherDetailView.location = location
            self.navigationController?.pushViewController(weatherDetailView, animated: true)
        }
    }

    @objc private func updateUserLocationOnMap() {
        getUserLocation()
    }
}

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse:
            setLocateMe(visible: true)
            locationManager.requestLocation()
        case .denied, .restricted, .notDetermined, .authorizedAlways:
            setLocateMe(visible: false)
        @unknown default:
          break
      }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Received Locations..")
        if let location = locations.first {
            mapView.setCenter(location.coordinate, animated: true)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error: \(error)")
    }
}

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let userLocation = mapView.userLocation.location else {
            return
        }
        fetchWeatherData(location: userLocation)
    }
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        print("Updated user location.")
    }
}
