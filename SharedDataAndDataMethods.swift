//  Storing data
//  Functions for updating data, calculating data based on API raw data
//      notes: static defaultValue only used when no previously saved data
//      notes: otherwise, always last saved data as "default"

import Foundation

//  MARK: 1. CustomizedDataTypes.swift
enum FoundationShade: String, Codable{
    case light, medium, tan, dark, deep
}

enum BurnLikeliness: String, Codable{
    case always, easily, sometimes, rarely, never
}

enum TanLikeliness: String, Codable{
    case never, rarely, sometimes, easily, always
}

typealias UVForecast = [(date: Date, uvIndex: Double)]

//  MARK: 2. SharedDataModels.swift (UserData and EnvironmentData structs)
struct UserData: Codable {
    var name: String
    var burnLikeliness: BurnLikeliness
    var tanLikeliness: TanLikeliness
    var foundationShade: FoundationShade
    var skinType: Int
    var spfUsed: Int
    
    static let defaultValue = UserData(name: "Me", burnLikeliness: .sometimes, tanLikeliness: .sometimes, foundationShade: .medium, skinType: 3, spfUsed: 15)
    
    mutating func calculateSkinType() {
        if burnLikeliness == .always {
            skinType = 1
            return
        }
        
        if foundationShade == .deep {
            skinType = 6
            return
        }
        
        let burnValue: Double
        switch burnLikeliness {
        case .always: burnValue = 1
        case .easily: burnValue = 2.25
        case .sometimes: burnValue = 3.5
        case .rarely: burnValue = 4.75
        case .never: burnValue = 6
        }
        
        let tanValue: Double
        switch tanLikeliness {
        case .never: tanValue = 1
        case .rarely: tanValue = 2.25
        case .sometimes: tanValue = 3.5
        case .easily: tanValue = 4.75
        case .always: tanValue = 6
        }
        
        let shadeValue: Double
        switch foundationShade {
        case .light: shadeValue = 1
        case .medium: shadeValue = 2.25
        case .tan: shadeValue = 3.5
        case .dark: shadeValue = 4.75
        case .deep: shadeValue = 6
        }
        
        let averageValue = (burnValue + tanValue + shadeValue) / 3
        skinType = Int(round(averageValue))
    }
}

struct EnvironmentData: Codable {
    var latitude: Double
    var longitude: Double
    var sunriseTime: Date
    var sunmaxTime: Date
    var sunsetTime: Date
    var uv: Double
    var minToReapp: Int
    var uvForecasts: UVForecast
    var spfRecm: Int
    var nextTime: Date
    
    init(latitude: Double, longitude: Double, sunriseTime: Date, sunmaxTime: Date, sunsetTime: Date, uv: Double, minToReapp: Int, uvForecasts: UVForecast, spfRecm: Int, nextTime: Date) {
        self.latitude = latitude
        self.longitude = longitude
        self.sunriseTime = sunriseTime
        self.sunmaxTime = sunmaxTime
        self.sunsetTime = sunsetTime
        self.uv = uv
        self.minToReapp = minToReapp
        self.uvForecasts = uvForecasts
        self.spfRecm = spfRecm
        self.nextTime = nextTime
    }
    
    static let defaultValue = EnvironmentData(
        latitude: 37.334606,
        longitude: -122.009102,
        sunriseTime: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!,
        sunmaxTime: Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!,
        sunsetTime: Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date())!,
        uv: 5.0,
        minToReapp: 180,
        uvForecasts: [],
        spfRecm: 3,
        nextTime: Calendar.current.date(byAdding: .minute, value: 2, to: Date())!
    )
    
    enum CodingKeys: String, CodingKey {
        case latitude, longitude, sunriseTime, sunmaxTime, sunsetTime, uv, minToReapp, uvForecasts, spfRecm, nextTime
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        latitude = try container.decode(Double.self, forKey: .latitude)
        longitude = try container.decode(Double.self, forKey: .longitude)
        sunriseTime = try container.decode(Date.self, forKey: .sunriseTime)
        sunmaxTime = try container.decode(Date.self, forKey: .sunmaxTime)
        sunsetTime = try container.decode(Date.self, forKey: .sunsetTime)
        uv = try container.decode(Double.self, forKey: .uv)
        minToReapp = try container.decode(Int.self, forKey: .minToReapp)
        let forecastArray = try container.decode([[String: Double]].self, forKey: .uvForecasts)
        uvForecasts = forecastArray.compactMap { dict in
            guard let dateString = dict.keys.first,
                  let date = ISO8601DateFormatter().date(from: dateString),
                  let uvIndex = dict.values.first else {
                return nil
            }
            return (date: date, uvIndex: uvIndex)
        }
        spfRecm = try container.decode(Int.self, forKey: .spfRecm)
        nextTime = try container.decode(Date.self, forKey: .nextTime)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
        try container.encode(sunriseTime, forKey: .sunriseTime)
        try container.encode(sunmaxTime, forKey: .sunmaxTime)
        try container.encode(sunsetTime, forKey: .sunsetTime)
        try container.encode(uv, forKey: .uv)
        try container.encode(minToReapp, forKey: .minToReapp)
        let forecastArray = uvForecasts.map { [ISO8601DateFormatter().string(from: $0.date): $0.uvIndex] }
        try container.encode(forecastArray, forKey: .uvForecasts)
        try container.encode(spfRecm, forKey: .spfRecm)
        try container.encode(nextTime, forKey: .nextTime)
    }
}

//  MARK: 3. SharedDataManager class for loading and saving data
class SharedDataManager {
    static let shared = SharedDataManager()
    
    private let userDefaults: UserDefaults?
    private let userDataKey = "UserData"
    private let environmentDataKey = "EnvironmentData"
    
    private init() {
        self.userDefaults = UserDefaults(suiteName: "group.com.morphace.parasol")
    }
    
    func getUserData() -> UserData {
        guard let data = userDefaults?.data(forKey: userDataKey),
              let userData = try? JSONDecoder().decode(UserData.self, from: data) else {
            return UserData.defaultValue
        }
        return userData
    }
    
    func saveUserData(_ userData: UserData) {
        if let encoded = try? JSONEncoder().encode(userData) {
            userDefaults?.set(encoded, forKey: userDataKey)
        }
    }
    
    func getEnvironmentData() -> EnvironmentData {
        guard let data = userDefaults?.data(forKey: environmentDataKey),
              let environmentData = try? JSONDecoder().decode(EnvironmentData.self, from: data) else {
            return EnvironmentData.defaultValue
        }
        return environmentData
    }
        
    func saveEnvironmentData(_ environmentData: EnvironmentData) {
        if let encoded = try? JSONEncoder().encode(environmentData) {
            userDefaults?.set(encoded, forKey: environmentDataKey)
        }
    }
}
