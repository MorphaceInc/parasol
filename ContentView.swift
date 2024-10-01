//
//  ContentView.swift
//  parasol
//
//  Created by Jia Xi Chen on 2024-08-27.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var timeZoneObserver = TimeZoneObserver()
    @State private var buttonPosition = CGPoint(x: UIScreen.main.bounds.width - 100, y: 300)
    
    @ObservedObject private var animationManager = AnimationManager.shared
    @State private var isAnimatingWiggle = true
    @State private var isAnimatingReload = true
    
    //  begin UI use
    @State private var currentPage: Page = .regular
    @State private var currentImageName: String = "regular"
    @State private var userData: UserData
    @State private var isEditingName = false
    init() {
        _userData = State(initialValue: SharedDataManager.shared.getUserData())
    }
    //  end UI use
    
    let locationService = LocationService()
    
    var body: some View {
        TabView {
            //  MARK: uv dashboard page
            GeometryReader { outerGeometry in
                ZStack(alignment: .top) {
                    ScrollView {
                        VStack(spacing: 20) {
                            Spacer()
                            // middle scrolling section - animation bottle
                            switch animationManager.currentView {
                            case .reload:
                                AnimatedShakeView(gifName: "Reload", isAnimating: .constant(true))
                                    .frame(height: outerGeometry.size.height * 0.4)
                            case .wiggle:
                                AnimatedShakeView(gifName: "Wiggle", isAnimating: .constant(true))
                                    .frame(height: outerGeometry.size.height * 0.4)
                                    .onTapGesture {
                                        Task {
                                            print("case .wiggle .onTapGesture triggered handleButtonPressWithAnimation")
                                            await animationManager.handleButtonPressWithAnimation()
                                            print("case .wiggle .onTapGesture triggered updateButtonState")
                                        }
                                    }
                            case .drain:
                                SunscreenDepletionView()
                                    .frame(height: outerGeometry.size.height * 0.4)
                            }
                            
                            // bottom scrolling section - UV plot
                            UVIndexView()
                                .frame(height: outerGeometry.size.height * 0.7, alignment: .center)
                        }
                        .padding(.top, outerGeometry.size.height * 0.4)
                    }
                    
                    //  Top panel
                    GeometryReader { geometry in
                        VStack(spacing: 0) {
                            dashboardFloatElement()
                                .frame(width: geometry.size.width * 0.75, height: geometry.size.height * 0.25)
                            Spacer()
                        }
                        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
                        .offset(y: geometry.frame(in: .global).minY > 0 ? geometry.frame(in: .global).minY : 0)
                    }
                }
            }
            .background(Color.backgroundPrimary)
            .tabItem {
                Image(systemName: "sun.horizon.fill")
            }.onAppear {
                animationManager.updateCurrentView()
                if isFirstLaunch() {
                    print("first ever launch detected")
                    StateManager.shared.handleFirstOpen()
                } else {
                    print("regular launch detected")
                }
            }
            .onReceive(timeZoneObserver.$timeZoneChanged) { changed in
                if changed {
                    print("timeZoneObserver changed .onReceive triggered handleTimeZoneChange")
                    StateManager.shared.handleTimeZoneChange()
                }
            }
            .overlay(
                FloatingButton() {
                    print("floating button pressed!")
                    Task { await animationManager.handleButtonPressWithAnimation() }
                }.disabled(AnimationManager.shared.isLoading)
            )
            
            //  MARK: user profile page
            GeometryReader { geometry in
                VStack(spacing: 20) {
                    VStack {
                        Spacer()
                            .frame(height: geometry.size.height * 0.05)
                        ZStack(alignment: .leading) {
                            if isEditingName {
                                TextField("Name", text: $userData.name)
                                    .font(.largeTitleCustom)
                                    .foregroundColor(.textPrimary)
                                    .multilineTextAlignment(.center)
                                    .onSubmit {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            isEditingName = false
                                        }
                                        SharedDataManager.shared.saveUserData(userData)
                                    }
                                    .transition(.opacity)
                            } else {
                                Text(userData.name.isEmpty ? "Enter Name": userData.name)
                                    .font(.largeTitleCustom)
                                    .foregroundColor(userData.name.isEmpty ? .gray: .textPrimary)
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            isEditingName = true
                                        }
                                    }
                                    .transition(.opacity)
                            }
                        }
                        .frame(width: geometry.size.width * 0.8, height: geometry.size.height * 0.1)
                        .background(Color.backgroundPrimary)
                        
                        Text("skin profile")
                            .font(.headlineCustom)
                            .foregroundColor(.textPrimary)
                    }
                    
                    midProfileElement(currentImageName: $currentImageName, geometry: geometry)
                    
                    botProfileElement(userData: $userData, currentPage: $currentPage, currentImageName: $currentImageName, geometry: geometry)
                    
                }
                .background(Color.backgroundPrimary)
                .navigationBarHidden(true)
            }.tabItem {
                Image(systemName: "person.fill")
            }
            
            //  MARK: debugging values
            ScrollView {
                VStack {
                    let envData = SharedDataManager.shared.getEnvironmentData()
                    let useData = SharedDataManager.shared.getUserData()
                    
                    Text("\(useData.name) with skin type \(useData.skinType), using SPF \(useData.spfUsed);")
                    Text("located lat \(envData.latitude), long \(envData.longitude)")
                    Text("\nsunMax at \(envData.sunmaxTime)")
                    Text("sunSet at \(envData.sunsetTime)")
                    Text("\nreapply after \(envData.minToReapp) min")
                    
                    Button("[success] day start - update coordinates"){
                        locationService.getCurrentLocation {_ in
                        }
                    }.buttonStyle(.borderedProminent)
                    
                    
                    Button("[success] day start - sunrise, max, set Times"){
                        APIService.shared.fetchTodayJSON(latitude: envData.latitude, longitude: envData.longitude) { result in
                            switch result {
                            case .success(let jsondata):
                                //  WHAT TO DO
                                APIService.shared.updatesunmaxTimeAndsunsetTime(jsonData: jsondata)
                            case .failure(let error):
                                print(error)
                            }
                        }
                    }.buttonStyle(.borderedProminent)
                    
                    Button("[success] upper day - uv, minToReapp"){
                        APIService.shared.fetchTodayJSON(latitude: envData.latitude, longitude: envData.longitude) { result in
                            switch result {
                            case .success(let jsondata):
                                APIService.shared.updateUVAndMinToReappOnForecast(jsonData: jsondata)
                            case .failure(let error):
                                print(error)
                            }
                        }
                    }.buttonStyle(.borderedProminent)
                    
                    Button("[success] lower day - uv, minToReapp"){
                        APIService.shared.fetchTodayJSON(latitude: envData.latitude, longitude: envData.longitude) { result in
                            switch result {
                            case .success(let jsondata):
                                APIService.shared.updateUVAndMinToReapp(jsonData: jsondata)
                            case .failure(let error):
                                print(error)
                            }
                        }
                    }.buttonStyle(.borderedProminent)
                    
                    Button("[success] sunset - spfRecm, Forecasts"){
                        APIService.shared.fetchTomorrowJSON(latitude: envData.latitude, longitude: envData.longitude) { result in
                            switch result {
                            case .success(let jsondata):
                                APIService.shared.updateSpfRecm(jsonData: jsondata)
                                APIService.shared.updateUVForecast(jsonData: jsondata)
                            case .failure(let error):
                                print(error)
                            }
                        }
                    }.buttonStyle(.borderedProminent)
                    
                    List {
                        ForEach(envData.uvForecasts, id: \.0) { forecast in
                            HStack {
                                Text("\(forecast.0)")
                                Spacer()
                                Text(String(format: "%.4f", forecast.1))
                            }
                        }
                    }
                    .frame(height: CGFloat(envData.uvForecasts.count * 50))
                    
                }
            }.tabItem {
                Image(systemName: "wrench.and.screwdriver.fill")
            }
        }
        .customTabViewAppearance()
    }
    
    private func isFirstLaunch() -> Bool {
        let key = "hasLaunchedBefore"
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: key)
        if !hasLaunchedBefore {
            UserDefaults.standard.set(true, forKey: key)
            return true
        }
        return false
    }
}

//  MARK: for tab 1 detecting timezone
class TimeZoneObserver: ObservableObject {
    @Published var timeZoneChanged = false
    private var lastKnownTimeZone: TimeZone?    // for debugging
    
    init() {
        lastKnownTimeZone = TimeZone.current    // for debugging
        NotificationCenter.default.addObserver(self, selector: #selector(timeZoneDidChange), name: NSNotification.Name.NSSystemTimeZoneDidChange, object: nil)
        print("TimeZoneObserver initialized with time zone: \(TimeZone.current.identifier)")
    }
    
    @objc func timeZoneDidChange() {    // function called when notification received that NSSytemTimeZoneDidChange
        let newTimeZone = TimeZone.current  // for debugging
        print("Time zone change detected")
        print("Previous time zone: \(lastKnownTimeZone?.identifier ?? "Unknown")")
        print("New time zone: \(newTimeZone.identifier)")
        
        if newTimeZone != lastKnownTimeZone {   // for debugging
            timeZoneChanged.toggle()
            lastKnownTimeZone = newTimeZone // for debugging
        } else {    // for debugging
            print("False alarm: Time zone hasn't actually changed")
        }
    }
}
