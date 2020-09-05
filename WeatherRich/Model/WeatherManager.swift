import Foundation
import CoreLocation

protocol WeatherManagerDelegate {
  func didUpdateWeather(_ weatherManager: WeatherManager, weather: WeatherModel)
  func didFailWithError(error: Error)
}

struct WeatherManager {
  private enum Constants {
    static let baseUrl = "https://api.openweathermap.org/data/2.5/weather?"
    static let apiKey = "385903cc9f57dc0517d10aea57191d6f"
  }
    
  private enum PlaceMarkResult {
    case success(LocatioinString)
    case failure(Swift.Error)
  }
  
  public enum WeatherError: Swift.Error, CustomStringConvertible {
    case placemarkNotFound
    case invalidJsonReceived
    case serverError(String)
    
    public var description: String {
      switch self {
      case .invalidJsonReceived:
        return "Invalid json received from server."
      case .placemarkNotFound:
        return "Place not found."
      case .serverError(let message):
        return message
      }
    }
    
    public var localizedDescription: String {
      return description
    }
  }
  
  
  var delegate: WeatherManagerDelegate?
  private typealias GetAreaNameFromLocationCompletionBlock = (PlaceMarkResult) -> Void
  private typealias LocatioinString = String
  
  
  func fetchWeather(location: CLLocation) {
    if Reachability.isConnectedToNetwork() == true {
        debugPrint("Connected to the internet")
      fetchWithURL(location: location)
    } else {
        debugPrint("No internet connection")
      noConnection()
    }

  }
  
  func fetchWithURL(location: CLLocation){
    var url = Constants.baseUrl
    getAreaNameFrom(location: location) { (result) in
      switch result {
      case .success(let locationString):
        url = url.appending("q=\(locationString)")
      case .failure(_):
        url = url.appending("lat=\(location.coordinate.latitude)&lon=\(location.coordinate.longitude)")
      }
      url = url.appending("&appid=\(Constants.apiKey)&units=metric")
      self.performRequest(with: url)
    }

  }
    
  func performRequest(with urlString: String) {
    if let url = URL(string: urlString) {
      let session = URLSession(configuration: .default)
      let task = session.dataTask(with: url) { (data, response, error) in
        if error != nil {
          self.delegate?.didFailWithError(error: error!)
          return
        }
        if let safeData = data {
          if let weather = self.parseJSON(safeData) {
            self.delegate?.didUpdateWeather(self, weather: weather)
          }
        }
      }
      task.resume()
    }
  }
  
  func noConnection(){
    print("No Connnection")
    guard let id = UserDefaults.standard.string(forKey: "Condition"), let temperature =  UserDefaults.standard.string(forKey: "Temperature") ,let name = UserDefaults.standard.string(forKey: "Location") else {
        /// either no value in rewardField, or value is not Int
      let weather = WeatherModel(conditionId: 0, cityName: "1st time,no net,try again", temperature: 0.0)
      self.delegate?.didUpdateWeather(self, weather: weather)

        return
    }
    
    let double = NSString(string: temperature)
    let noInternetId = Int(id)!
    
    let weather = WeatherModel(conditionId: noInternetId, cityName: name, temperature: double.doubleValue)
    self.delegate?.didUpdateWeather(self, weather: weather)
  }
  
  func parseJSON(_ weatherData: Data) -> WeatherModel? {
    let decoder = JSONDecoder()
    do {
      let decodedData = try decoder.decode(WeatherData.self, from: weatherData)
      let id = decodedData.weather[0].id
      let temp = decodedData.main.temp
      let name = decodedData.name
      let defaults = UserDefaults.standard
      defaults.set(temp, forKey: "Temperature")
      defaults.set(id, forKey: "Condition")
      defaults.set(name, forKey: "Location")

      let weather = WeatherModel(conditionId: id, cityName: name, temperature: temp)
      return weather
      
    } catch {
      delegate?.didFailWithError(error: error)
      return nil
    }
  }
  
  private func getAreaNameFrom(location: CLLocation, completion: @escaping GetAreaNameFromLocationCompletionBlock) {
    CLGeocoder().reverseGeocodeLocation(location, preferredLocale: nil) { (placemarks, error) in
      if let error = error {
        completion(.failure(error))
        return
      }
      if let placemark = placemarks?.first {
        var query = [String]()
        if let city = placemark.locality {
          query.append(city)
        }
        if let country = placemark.country {
          query.append(country)
        }
        
        if query.count > 0, let string = query.joined(separator: ",").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
          completion(.success(string))
        } else {
          completion(.failure(WeatherError.placemarkNotFound))
        }
      } else {
        completion(.failure(WeatherError.placemarkNotFound))
      }
    }
  }
}


