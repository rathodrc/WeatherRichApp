import UIKit
import MapKit
import CoreLocation

class WeatherDetailViewController: UIViewController {

    private enum Constants {
        static let cameraAltitude = CLLocationDistance(400)
        static let cameraPitch = CGFloat(0)
        static let cameraHeading = CLLocationDirection(0)
    }

    var location: CLLocation?
    var weatherManager = WeatherManager()
    @IBOutlet var tableView: UITableView!
    @IBOutlet var mapView: MKMapView!

    private let datasource = WeatherDataSource()

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = datasource
        tableView.delegate = datasource
        weatherManager.delegate = self
        tableView.tableFooterView = UIView()
      weatherManager.delegate = self

        updateMap()
        fetchWeatherData()
    }
    
    private func fetchWeatherData() {
        guard let location = location else {
            return
        }
        weatherManager.fetchWeather(location: location)
    }

    private func updateMap() {
        guard let location = location else {
            return
        }
        // setup camera of map
        let camera = MKMapCamera(lookingAtCenter: location.coordinate, fromDistance: Constants.cameraAltitude, pitch: Constants.cameraPitch,
        heading: Constants.cameraHeading)
        mapView.setCamera(camera, animated: false)

        //  add simple pin.
        let annotation = MKPointAnnotation()
        annotation.coordinate = location.coordinate
        mapView.addAnnotation(annotation)
    }

}

extension WeatherDetailViewController: WeatherManagerDelegate {

    func didUpdateWeather(_ weatherManager: WeatherManager, weather: WeatherModel) {
        DispatchQueue.main.async {
          self.datasource.rows.removeAll()
          let nameData = ["key": "Location", "value" : "\(weather.cityName)"]
          self.datasource.rows.append(nameData)
          let tempData = ["key": "Temperature", "value" : "\(weather.temperatureString) celcius"]

          self.datasource.rows.append(tempData)
          let conditionData = ["key": "Condition", "value" : "\(weather.conditionName)"]
          self.datasource.rows.append(conditionData)
          self.tableView.reloadData()
        }
    }
    func didFailWithError(error: Error) {
        print(error)
    }
}
