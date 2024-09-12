//  Detecting and keeping track of things
//      1. Button state
//      2. First opening app and timezone change
//      3. Background sunset tasks
//      4. Animation state

import Foundation
import BackgroundTasks
import Combine

class StateManager {
    static let shared = StateManager()
    private init() {}
    
    //  MARK: 1. Button state: determining what to do depending on the time of day
    func canPressButton() -> Bool {
        let envData = SharedDataManager.shared.getEnvironmentData()
        if isFirstPressToday() {
            print("found it's first press Today")
            return true
        } else {
            print("found it's nth press today")
            if Date() < envData.sunriseTime {
                print("found now before sunrise, cannot press")
                return false
            } else if Date() > envData.sunsetTime {
                print("found now after sunset, cannot press")
                return false
            } else {
                print("found now is inbetween sunrise & sunset, can press")
                return true
            }
        }
    }
    
    func isFirstPressToday() -> Bool {
        guard let lastPress = UserDefaults.standard.object(forKey: "lastPressDate") as? Date else { return true }
        return !Calendar.current.isDate(lastPress, inSameDayAs: Date())
    }
    
    func handleButtonPress() async -> Bool {
        do {
            let locationService = LocationService()
            let pressTime = Date()
            let forecastsDate = SharedDataManager.shared.getEnvironmentData().uvForecasts.first?.0
            
            if isFirstPressToday() {    // first press today
                locationService.getCurrentLocation {_ in}   // update location
                let locData = SharedDataManager.shared.getEnvironmentData()
                let lat = locData.latitude
                let long = locData.longitude
                
                APIService.shared.fetchTodayJSON(latitude: lat, longitude: long) { result in
                    switch result {
                    case .success(let jsondata):
                        APIService.shared.updatesunmaxTimeAndsunsetTime(jsonData: jsondata) // update sunTimes
                        let sunData = SharedDataManager.shared.getEnvironmentData()
                        let sunriseTime = sunData.sunriseTime
                        let sunmaxTime = sunData.sunmaxTime
                        let sunsetTime = sunData.sunsetTime
                        
                        if pressTime < sunsetTime { // press - sunset
                            self.scheduleSunsetTasks()
                            let shouldUpdateOnForecast = sunriseTime < pressTime && pressTime < sunmaxTime && forecastsDate != nil && Calendar.current.isDate(Date(), inSameDayAs: forecastsDate!)
                            
                            if shouldUpdateOnForecast {
                                APIService.shared.updateUVAndMinToReappOnForecast(jsonData: jsondata)
                            } else {
                                APIService.shared.updateUVAndMinToReapp(jsonData: jsondata)
                            }
                            
                        } else {    // sunset - press
                            self.performSunsetTasks()
                        }
                    case .failure(let error):
                        print(error)
                    }
                }
                
            } else {    // iterative presses today
                let lat = SharedDataManager.shared.getEnvironmentData().latitude
                let long = SharedDataManager.shared.getEnvironmentData().longitude
                let sunriseTime = SharedDataManager.shared.getEnvironmentData().sunriseTime
                let sunmaxTime = SharedDataManager.shared.getEnvironmentData().sunmaxTime   // sunset taken care of with canPressButton
                
                APIService.shared.fetchTodayJSON(latitude: lat, longitude: long) { result in
                    switch result {
                    case .success(let jsondata):
                        let shouldUpdateOnForecast = sunriseTime < pressTime && pressTime < sunmaxTime && forecastsDate != nil && Calendar.current.isDate(Date(), inSameDayAs: forecastsDate!)
                        
                        if shouldUpdateOnForecast {
                            APIService.shared.updateUVAndMinToReappOnForecast(jsonData: jsondata)
                        } else {
                            APIService.shared.updateUVAndMinToReapp(jsonData: jsondata)
                        }
                    case .failure(let error):
                        print(error)
                    }
                }
            }
            UserDefaults.standard.set(Date(), forKey: "lastPressDate")
            return true
        }
    }
    
    //  MARK: 2. First opening the App and timezone change: updating every location-dependent data
    func handleTimeZoneChange() {
        print("executing function handleTimeZoneChange")
        UserDefaults.standard.removeObject(forKey: "lastPressDate")
        handleFirstOpen()
    }
    
    func handleFirstOpen() {
        print("executing function handleFirstOpen")
        let locationService = LocationService()
        locationService.getCurrentLocation {_ in}   // update location
        let envData = SharedDataManager.shared.getEnvironmentData()
        
        // update today's sunTimes
        APIService.shared.fetchTodayJSON(latitude: envData.latitude, longitude: envData.longitude) { result in
            switch result {
            case .success(let jsondata):
                APIService.shared.updatesunmaxTimeAndsunsetTime(jsonData: jsondata)
            case .failure(let error):
                print(error)
            }
        }
        
        // update tomorrow's forecasts and SPF recommendation
        APIService.shared.fetchTomorrowJSON(latitude: envData.latitude, longitude: envData.longitude) { result in
            switch result {
            case .success(let jsondata):
                APIService.shared.updateSpfRecm(jsonData: jsondata)
                APIService.shared.updateUVForecast(jsonData: jsondata)
            case .failure(let error):
                print(error)
            }
        }
    }

    //  MARK: 3. Background sunset tasks: updating tomorrow uv and SPF recommendation
    //  MARK: *** we're not calling performSunsetTasks here?
    func scheduleSunsetTasks() {
        let envData = SharedDataManager.shared.getEnvironmentData()
        print("executing function scheduleSunSetTasks, at time \(envData.sunsetTime)")
        
        let request = BGAppRefreshTaskRequest(identifier: "group.com.morphace.parasol.refresh")
        request.earliestBeginDate = envData.sunsetTime
        do { 
            try BGTaskScheduler.shared.submit(request)
            print("scheduled task for \(envData.sunsetTime)")
        } catch {
            //  MARK: *** try again in...?
            //  MARK: *** it's erroring out right now
            print("can't schedule app refresh \(error)")
        }
    }
    
    func performSunsetTasks() {
        let envData = SharedDataManager.shared.getEnvironmentData()
        print("executing function performSunsetTasks")
        // update tomorrow's forecasts and SPF recommendation
        APIService.shared.fetchTomorrowJSON(latitude: envData.latitude, longitude: envData.longitude) { result in
            switch result {
            case .success(let jsondata):
                APIService.shared.updateSpfRecm(jsonData: jsondata)
                APIService.shared.updateUVForecast(jsonData: jsondata)
            case .failure(let error):
                print(error)
            }
        }
    }
}

//  MARK: 4. Handling loading animation
class AnimationManager: ObservableObject {
    static let shared = AnimationManager()
    @Published var isLoading = false
    @Published var currentView: SunscreenState = .wiggle
    enum SunscreenState {
        case drain
        case reload
        case wiggle
    }
    
    private init() {}
    
    @MainActor
    func handleButtonPressWithAnimation() async {
        guard !isLoading else { return }
            
        isLoading = true
        currentView = .reload
        
        let startTime = Date()
        let minAniDuration: TimeInterval = 2.5

        let success = await StateManager.shared.handleButtonPress()
        let elapsedTime = Date().timeIntervalSince(startTime)
        if elapsedTime < minAniDuration {
            try? await Task.sleep(seconds: minAniDuration - elapsedTime)
        }
        
        isLoading = false
        
        if success {
            UserDefaults.standard.set(Date(), forKey: "lastPressDate")
            updateCurrentView()
        } else {
            currentView = .wiggle
        }
    }
    
    func updateCurrentView() {
        if Date() > SharedDataManager.shared.getEnvironmentData().nextTime {
            currentView = .wiggle
        } else {
            currentView = .drain
        }
    }
}

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async throws {
        let duration = UInt64(seconds * 1_000_000_000)
        try await Task.sleep(nanoseconds: duration)
    }
}
