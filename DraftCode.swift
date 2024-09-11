//  MARK: Time Methods
//  1. [class TimelineManager] Setting up timeline for widget: animation state vs. plot state
//  2. [class TimerManager] Setting up timer for widget: ani_A state vs. ani_B state
//  [fused because exclusively used] class TimeChecker Determining before or after sunmax, updating date based on minutes

import Foundation

//  MARK: unused
enum FetchFunctionType {
    case beforeSunmaxTime
    case afterSunmaxTime
}

//  MARK: unfinished
class TimelineManager {
    func setTimeLine() {
        //  1e) using shared.sunmaxTime and sunsetTime
    }
    
    func determineWidgetDisplay() -> WidgetDisplayType {
        //  1e)i) return .animationA, .animationB, or .plotC based on current time
        return .animationA
    }
    
    func determineFetchFunction() -> FetchFunctionType {
        let envData = SharedDataManager.shared.getEnvironmentData()
        let currentTime = Date()
        if currentTime < envData.sunmaxTime {
            return .beforeSunmaxTime
        } else {
            return .afterSunmaxTime
        }
    }
    
//    //  example usage:
//    let timelinemanager = TimeLineManager.shared
//    let fetchFunction = timelineManager.determineFetchFunction()
//
//    switch fetchFunction {
//    case .beforeSunmaxTime:
//        apiService.updateUVAndMinToReappOnForecast()
//    case .afterSunmaxTime:
//        apiService.updateUVAndMinToReapp()
//    }
    
    //  calculate next time after time interval minToReapp
    //  MARK: may not be needed, if timer widget can take minToReapp instead of abs Time. Plus, user click initiates next timer, so...
    func calculateNextTime(from currentTime: Date, afterMinutes minutes: Int) -> Date {
        return Calendar.current.date(byAdding: .minute, value: minutes, to: currentTime) ?? currentTime
    }
}

//  MARK: unfinished
class TimerManager {
    func setTimer(for duration: TimeInterval, completion: @escaping () -> Void) {
        //  1f) & 2c), set minToReapp duration
    }
}


//  MARK: VisualMethods
//  1. [class ChartManager] Plotting chart from data
//  2. [class WidgetManager] Updating display based on type

import Foundation

//  MARK: unused
enum ChartDisplayType {
    case widget
    case inApp
}

//  MARK: unused
enum WidgetDisplayType {
    case animationA
    case animationB
    case plotC
}

class ChartManager {
    //  MARK: unfinished
    func plotUVForecastChart(for displayType: ChartDisplayType) {
        let uvForecasts = SharedDataManager.shared.getEnvironmentData().uvForecasts
        
        switch displayType {
        case .widget:
            plotBasicChart(with: uvForecasts)
        case .inApp:
            plotEnhancedChart(with: uvForecasts)
        }
    }
    
    //  MARK: unfinished
    private func plotBasicChart(with forecasts: UVForecast) {
        //  implement plotting for widget, no sun indicator becuase widget only displays outside sun hours
        //  consider visually SPF rec and UV max show
    }
    
    //  MARK: unfinished
    private func plotEnhancedChart(with forecasts: UVForecast) {
        plotBasicChart(with: forecasts)
        
        if isWithinSunHours() {
            addSunIndicator()
        }
    }
    
    //  MARK: unfinished
    private func isWithinSunHours() -> Bool {
        let envData = SharedDataManager.shared.getEnvironmentData()
        let currentTime = Date()
        return currentTime >= envData.sunriseTime && currentTime <= envData.sunsetTime
    }
    
    //  MARK: unfinished
    private func addSunIndicator() {
        let envData = SharedDataManager.shared.getEnvironmentData()
        
        //  add sun indicator to the chart
        //  show current UV, past UV, forecast UV (necessary?, just plot the updated UVForecast array)
        //  drawing the sun icon at appropriate position (based on time from UVForecast array)
    }
    
}

//  MARK: unfinished
class WidgetManager {
    func updateWidgetDisplay(to displayType: WidgetDisplayType) {
        //  3e) display based on type logic
    }
    
    func adjustAnimationA(for duration: TimeInterval) {
        //  takes minToReapp in Int
    }
}

