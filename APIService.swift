//  Fetching data from location services and openUV
//  Location: auto updates the EnvironmentData.latitude and .longitude with each fetch
//  UV Info: auto updates with the parsing at the 2nd step
//      step 1. let JSON = fetch() and 2. params = parse(JSON)

import Foundation
import CoreLocation

//  MARK: 1. LocationService class
class LocationService: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var locationCompletion: ((Double, Double)?) -> Void = { _ in }
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func getCurrentLocation(completion: @escaping ((Double, Double)?) -> Void) {
        locationCompletion = completion
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.requestLocation()
        default:
            locationCompletion(nil)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            locationCompletion(nil)
            return
        }
        
        let latitude = location.coordinate.latitude
        let longitude = location.coordinate.longitude
        var currentData = SharedDataManager.shared.getEnvironmentData()
        currentData.latitude = latitude
        currentData.longitude = longitude
        
        getCityName(from: location) { locationName in
            currentData.cityName = locationName
            SharedDataManager.shared.saveEnvironmentData(currentData)
            self.locationCompletion((latitude, longitude))
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
        locationCompletion(nil)
    }
    
    func getCityName(from location: CLLocation, completion: @escaping (String) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if let error = error {
                print("Reverse geocoding failed: \(error.localizedDescription)")
                completion("Unknown Location")
                return
            }
            
            guard let firstPlacemark = placemarks?.first else {
                print("No placemarks found")
                completion("Unknown Location")
                return
            }
            
            // Try to get the most specific name available
            if let locality = firstPlacemark.locality {
                completion(locality)
            } else if let subAdministrativeArea = firstPlacemark.subAdministrativeArea {
                completion(subAdministrativeArea)
            } else if let administrativeArea = firstPlacemark.administrativeArea {
                completion(administrativeArea)
            } else if let country = firstPlacemark.country {
                completion(country)
            } else {
                completion("Unknown Location")
            }
        }
    }
}

//  MARK: 2. APIService class
class APIService {
    static let shared = APIService()
    
    private init() {}
    private let apiKey = "openuv-e9hqp7rm01dli5m-io"
    
    func fetchTodayJSON(latitude: Double, longitude: Double, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let urlString = "https://api.openuv.io/api/v1/uv?lat=\(latitude)&lng=\(longitude)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(apiKey, forHTTPHeaderField: "x-access-token")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: 0, userInfo: nil)))
                return
            }
            
            do {
                if let jsonResult = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    completion(.success(jsonResult))
                } else {
                    completion(.failure(NSError(domain: "Could not parse JSON as dictionary", code: 0, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    func fetchTomorrowJSON(latitude: Double, longitude: Double, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let lastSunmax = SharedDataManager.shared.getEnvironmentData().sunmaxTime
        let calendar = Calendar.current
        let tmr = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date())!)
        let offsetTime = calendar.dateComponents([.hour, .minute, .second], from: calendar.startOfDay(for: lastSunmax), to: lastSunmax)
        let tmrMax = calendar.date(byAdding: offsetTime, to: tmr)!
        print("guessing the tmr max time to be \(tmrMax)")

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime]
        let formattedDate = dateFormatter.string(from: tmrMax)
        let urlString = "https://api.openuv.io/api/v1/forecast?lat=\(latitude)&lng=\(longitude)&dt=\(formattedDate)"
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(apiKey, forHTTPHeaderField: "x-access-token")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data received", code: 0, userInfo: nil)))
                return
            }
            
            do {
                if let jsonResult = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                    completion(.success(jsonResult))
                } else {
                    completion(.failure(NSError(domain: "Could not parse JSON as dictionary", code: 0, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }
        task.resume()
    }
    
    //  MARK: 2a) functions for interpreting JSON data
    func convertISO8601StringToDate(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: dateString)
    }
    
    func convertSafeTimetoSunscreenTimer(_ st: Int) -> Int {
        let doubled = st * 2
        return min(doubled, 300)
    }
    
    func recommendSPFLevel(skinType: Int, uvIndex: Double) -> Int {
        let validSkinType = max(1, min(skinType, 6))
        
        let uvCategory: Int //  Determine UV category
        switch uvIndex {
        case ..<3:
            uvCategory = 0 // UV 1-2
        case 3..<6:
            uvCategory = 1 // UV 3-5
        case 6..<8:
            uvCategory = 2 // UV 6-7
        case 8..<11:
            uvCategory = 3 // UV 8-10
        default:
            uvCategory = 4 // UV 11+
        }
        
        let spfLevels = [   //  SPF level lookup table based on the image
            [3, 4, 5, 6, 6], // St1
            [2, 3, 4, 5, 6], // St2
            [2, 3, 4, 5, 6], // St3
            [1, 2, 3, 5, 6], // St4
            [1, 2, 3, 4, 5], // St5
            [1, 2, 3, 4, 5]  // St6
        ]
        
        return spfLevels[validSkinType - 1][uvCategory] //  Return the recommended SPF level
    }
    
    func adjustReapplyTime(SPF_used: Int, time_to_reapply: Int) -> Int {
        let adjustmentFactor: Double
        if SPF_used < 15 {
            adjustmentFactor = 0.8
        } else if SPF_used <= 30 {
            adjustmentFactor = 0.9
        } else {
            adjustmentFactor = 1.0 // No adjustment for SPF > 30
        }
        let adjustedTime = Double(time_to_reapply) * adjustmentFactor
        return Int(round(adjustedTime))
    }
    
    func calculateSafeExposureDosage(uvIndex: Double, minToReappConstantUV: Int) -> Double {
        return uvIndex * Double(minToReappConstantUV)
    }
    
    func calculateRealTimeToReachDosage(startDate: Date, safeDosage: Double, uvForecasts: UVForecast) -> Int {
        var accumulatedDosage: Double = 0
        var elapsedMinutes: Int = 0
        
        guard let startIndex = uvForecasts.firstIndex(where: { $0.date > startDate }) else {
            return 0
        }
        
        for i in startIndex..<uvForecasts.count {
            let currentForecast = uvForecasts[i]
            print("From \(currentForecast)")
            let nextForecast = i + 1 < uvForecasts.count ? uvForecasts[i + 1] : nil
            print("to before \(String(describing: nextForecast))")
            
            let timeInterval: TimeInterval
            if let next = nextForecast {
                timeInterval = next.date.timeIntervalSince(currentForecast.date)
            } else {
                timeInterval = 7200 // Default to two hours if it's the last forecast
            }
            
            let intervalMinutes = Int(timeInterval / 60)
            
            // Handle case where UV index is zero or very close to zero
            if currentForecast.uvIndex <= 0.01 {
                print("the current uv index too smol is \(currentForecast.uvIndex)")
                elapsedMinutes += intervalMinutes
                continue
            }
            
            let dosageInInterval = currentForecast.uvIndex * Double(intervalMinutes)
            
            if accumulatedDosage + dosageInInterval >= safeDosage {
                let remainingDosage = safeDosage - accumulatedDosage
                let additionalMinutes = min(intervalMinutes, Int(ceil(remainingDosage / currentForecast.uvIndex)))
                elapsedMinutes += additionalMinutes
                print("existed loop, lastly adding \(additionalMinutes)")
                break
            } else {
                accumulatedDosage += dosageInInterval
                print("UV Dosage accumulated \(accumulatedDosage)")
                elapsedMinutes += intervalMinutes
            }
        }
        return elapsedMinutes
    }
    
    func overwriteUVForecasts(timeNow: Date, uvNow: Double) {
        var currentData = SharedDataManager.shared.getEnvironmentData()
        
        guard let nearestIndex = currentData.uvForecasts.firstIndex(where: { $0.date >= timeNow }) else {
            print("No future time is found")
            return
        }
        
        let nearestForecast = currentData.uvForecasts[nearestIndex]
        
        if uvNow > nearestForecast.uvIndex {
            let difference = uvNow - nearestForecast.uvIndex
            for i in nearestIndex..<currentData.uvForecasts.count {
                currentData.uvForecasts[i].uvIndex += difference
            }
            SharedDataManager.shared.saveEnvironmentData(currentData)
        }
    }
    
    func convertminToReappToReappDateTime(_ minutes: Int) -> Date {
        return Calendar.current.date(byAdding: .minute, value: minutes, to: Date()) ?? Date()
    }
    
    //  MARK: 2b) functions for calculating and updating based on JSON data
    //  for day start, when user clicks
    func updatesunmaxTimeAndsunsetTime(jsonData: [String: Any]) {
        print("executing function updatesunmaxTimeAndsunsetTime")
        var currentData = SharedDataManager.shared.getEnvironmentData()
        
        if let result = jsonData["result"] as? [String: Any]{
            if let sunmaxString = result["uv_max_time"] as? String,
               let sunmaxTime = convertISO8601StringToDate(sunmaxString) {
                currentData.sunmaxTime = sunmaxTime
            } else {
                currentData.sunmaxTime = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date()
            }
            
            if let sunInfo = result["sun_info"] as? [String: Any],
               let sunTimes = sunInfo["sun_times"] as? [String: String],
               let sunsetString = sunTimes["sunset"],
               let sunsetTime = convertISO8601StringToDate(sunsetString) {
                currentData.sunsetTime = sunsetTime
            } else {
                currentData.sunsetTime = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
            }
            
            if let sunInfo = result["sun_info"] as? [String: Any],
               let sunTimes = sunInfo["sun_times"] as? [String: String],
               let sunriseString = sunTimes["sunriseEnd"],
               let sunriseTime = convertISO8601StringToDate(sunriseString) {
                currentData.sunriseTime = sunriseTime
            } else {
                currentData.sunsetTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
            }
            
        } else {
            currentData.sunmaxTime = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date()
            currentData.sunsetTime = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
        }
        
        SharedDataManager.shared.saveEnvironmentData(currentData)
    }
    
    //  for upper day iterative, from daystart to sunmaxTime
    func updateUVAndMinToReappOnForecast(jsonData: [String: Any]) {
        print("executing function updateUVAndMinToReappOnForecast")
        updateUVAndMinToReapp(jsonData: jsonData)
        
        let userData = SharedDataManager.shared.getUserData()
        var currentData = SharedDataManager.shared.getEnvironmentData()
        print("with skintype \(userData.skinType), spf \(userData.spfUsed), the recommendation is \(currentData.minToReapp) mins")
        let currentTime = Date()
        
        guard currentData.uv > 0 else {
            currentData.minToReapp = 180 // default 3 hours
            currentData.nextTime = convertminToReappToReappDateTime(currentData.minToReapp)
            SharedDataManager.shared.saveEnvironmentData(currentData)
            return
        }
        
        let safeExposureDosage = calculateSafeExposureDosage(uvIndex: currentData.uv, minToReappConstantUV: currentData.minToReapp)
        print("obtained safe exposure dosage is \(safeExposureDosage) from \(currentData.uv) times by \(currentData.minToReapp)")
        let timeToReachDosage = calculateRealTimeToReachDosage(startDate: currentTime, safeDosage: safeExposureDosage, uvForecasts: currentData.uvForecasts)

        guard timeToReachDosage > 0 else {
            currentData.minToReapp = 180 // default 3 hours
            currentData.nextTime = convertminToReappToReappDateTime(currentData.minToReapp)
            SharedDataManager.shared.saveEnvironmentData(currentData)
            return
        }
        
        currentData.minToReapp = timeToReachDosage
        currentData.nextTime = convertminToReappToReappDateTime(currentData.minToReapp)
        SharedDataManager.shared.saveEnvironmentData(currentData)
    }
    
    //  for lower day iterative, from sunmaxTime to sunsetTime
    func updateUVAndMinToReapp(jsonData: [String: Any]) {
        print("executing function updateUVAndMinToReapp")
        var currentData = SharedDataManager.shared.getEnvironmentData()
        let userData = SharedDataManager.shared.getUserData()
        
        if let result = jsonData["result"] as? [String: Any],
           let uv = result["uv"] as? Double {
            currentData.uv = uv
            
            let stKey = "st\(userData.skinType)"
            if let safeExposureTime = result["safe_exposure_time"] as? [String: Any] {
                if let safe_time = safeExposureTime[stKey] as? Int {
                    let minToReapp = convertSafeTimetoSunscreenTimer(safe_time)
                    currentData.minToReapp = adjustReapplyTime(SPF_used: userData.spfUsed, time_to_reapply: minToReapp)
                } else if safeExposureTime[stKey] is String {
                    currentData.minToReapp = 300
                }
            } else {
                currentData.minToReapp = 300
            }
        } else {
            currentData.uv = 5.0
            currentData.minToReapp = 300
        }
        
        currentData.nextTime = convertminToReappToReappDateTime(currentData.minToReapp)
        
        if let firstForecastDate = currentData.uvForecasts.first?.0 {
            if Calendar.current.isDate(Date(), inSameDayAs: firstForecastDate) {
                print("forecasts same day as today, checking if needs overwriting")
                overwriteUVForecasts(timeNow: Date(), uvNow: currentData.uv)
            }
        }
        
        SharedDataManager.shared.saveEnvironmentData(currentData)
    }
    
    //  for dayend, at sunsetTime
    func updateUVForecast(jsonData: [String: Any]) {
        print("executing function updateUVForecast")
        var currentData = SharedDataManager.shared.getEnvironmentData()
        
        if let result = jsonData["result"] as? [[String: Any]] {
            let newForecasts: UVForecast = result.compactMap { item in
                guard let uvTimeString = item["uv_time"] as? String,
                      let uvTime = convertISO8601StringToDate(uvTimeString) else {
                    return nil
                }
                
                let uvIndex: Double
                if let forecastUV = item["uv"] as? Double {
                    uvIndex = forecastUV
                } else if let forecastUVString = item["uv"] as? String,
                          let forecastUVDouble = Double(forecastUVString) {
                    uvIndex = forecastUVDouble
                } else {
                    return nil
                }
                return (date: uvTime, uvIndex: uvIndex)
            }
            currentData.uvForecasts = newForecasts
            SharedDataManager.shared.saveEnvironmentData(currentData)
        }
    }
    
    func updateSpfRecm(jsonData: [String: Any]) {
        print("executing function updateSpfRecm")
        var currentData = SharedDataManager.shared.getEnvironmentData()
        let userData = SharedDataManager.shared.getUserData()
        
        if let result = jsonData["result"] as? [[String: Any]] {
            let tmr_maxUV = result.compactMap { item -> Double? in
                if let uv = item["uv"] as? Double {
                    return uv
                } else if let uvString = item["uv"] as? String,
                          let uvDouble = Double(uvString) {
                    return uvDouble
                }
                return nil
            }.max() ?? 6.0 // default tmr_uv_max
            currentData.spfRecm = recommendSPFLevel(skinType: userData.skinType, uvIndex: tmr_maxUV)
        } else {
            currentData.spfRecm = 3 // default spf_recm
        }
        
        SharedDataManager.shared.saveEnvironmentData(currentData)
    }
}
