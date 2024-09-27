//
//  ContentView.swift
//  parasol
//
//  Created by Jia Xi Chen on 2024-08-27.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var timeZoneObserver = TimeZoneObserver()
    @State private var buttonPosition = CGPoint(x: UIScreen.main.bounds.width - 100, y: 300)
    
    @ObservedObject private var animationManager = AnimationManager.shared
    @State private var isAnimatingWiggle = true
    @State private var isAnimatingReload = true
    
    //  begin UI use
    @State private var userData: UserData
    @State private var isEditingName = false
    init() {
        _userData = State(initialValue: SharedDataManager.shared.getUserData())
    }
    //  end UI use
    
    let locationService = LocationService()
    
    var body: some View {
        TabView {
            //  MARK: 1st tab - Home page
            ScrollView {
                VStack(spacing: 20) {
                    // top section - header info
                    VStack(spacing: 10) {
                        Text("next app time \(UIDisplayFunctions().displayNextTime())")
                        Text("current uv \(SharedDataManager.shared.getEnvironmentData().uv)")
                        Text("current city \(SharedDataManager.shared.getEnvironmentData().cityName)")
                    }
                    .padding()
                    .background(Color.backgroundPrimary)
                    .cornerRadius(10)
                    .shadow(radius: 5)
                    
                    // middle section
                    switch animationManager.currentView {
                    case .reload:
                        AnimatedShakeView(gifName: "Reload", isAnimating: .constant(true))
                            .frame(height: 300)
                    case .wiggle:
                        AnimatedShakeView(gifName: "Wiggle", isAnimating: .constant(true))
                            .frame(height: 300)
                            .onTapGesture {
                                Task {
                                    print("case .wiggle .onTapGesture triggered handleButtonPressWithAnimation")
                                    await animationManager.handleButtonPressWithAnimation()
                                    print("case .wiggle .onTapGesture triggered updateButtonState")
                                }
                            }
                    case .drain:
                        SunscreenDepletionView()
                            .frame(height: 300)
                    }
                    
                    // bottom section - UV plot
                    UVIndexView()
                }
                .padding()
            }.tabItem {
                Image(systemName: "house")
                Text("Main page")
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
            
            //  MARK: 2nd tab - debugging values
            ScrollView {
                VStack {
                    let envData = SharedDataManager.shared.getEnvironmentData()
                    let useData = SharedDataManager.shared.getUserData()
                    
                    Text("skin type \(useData.skinType), using SPF \(useData.spfUsed);")
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
                Text("Display Values")
            }
            
            //  MARK: 3rd designed user profile
            NavigationView {
                VStack(spacing: 20) {
                    //  top section: name
                    Spacer()
                    VStack {
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
                            Text(userData.name)
                                .font(.largeTitleCustom)
                                .foregroundColor(.textPrimary)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        isEditingName = true
                                    }
                                }
                                .transition(.opacity)
                        }
                        Text("skin profile")
                            .font(.headlineCustom)
                            .foregroundColor(.textPrimary)
                    }
                    
                    //  middle section: background image
                    Image("regular")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                    
                    //  bottom section: info field
                    ZStack {
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.white)
                            .shadow(color: Color.blue.opacity(0.25), radius: 5.7, x: 0, y: 5)
                        
                        VStack {
                            HStack {
                                ProfileItemButton(title: "burns", value: userData.burnLikeliness.rawValue.capitalized, itemType: .burn, userData: $userData)
                                    .padding([.top, .leading], 5)
                                DottedDivider()
                                ProfileItemButton(title: "tans", value: userData.tanLikeliness.rawValue.capitalized, itemType: .tan, userData: $userData)
                                    .padding([.top, .trailing], 5)
                            }
                            DottedDivider(isHorizontal: true)
                            HStack {
                                ProfileItemButton(title: "foundation", value: userData.foundationShade.rawValue.capitalized, itemType: .foundation, userData: $userData, prefix: "uses")
                                    .padding([.bottom, .leading], 5)
                                DottedDivider()
                                ProfileItemButton(title: "SPF", value: String(userData.spfUsed), itemType: .spf, userData: $userData, prefix: "uses")
                                    .padding([.bottom, .trailing], 5)
                            }
                        }
                        .padding(20)
                        .background(Color.textPrimary.opacity(0.07))
                        .cornerRadius(25)
                    }
                    .padding(40)
                    //  MARK: opacity transition of the lower card
                    .transition(.opacity)
                }
                .background(Color.backgroundPrimary)
                .navigationBarHidden(true)
                .onAppear {
                    userData.calculateSkinType()
                }
            }.tabItem {
                Image(systemName: "bubbles.and.sparkles")
                Text("weee")
            }
        }
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
