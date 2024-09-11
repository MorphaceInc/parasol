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
    @State private var canPressButton: Bool = true
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
                        Text("val 1 placeholder")
                        Text("val 2 placeholder")
                        Text("val 3 placeholder")
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
                                    await animationManager.handleButtonPressWithAnimation()
                                }
                            }
                    case .drain:
                        SunscreenDepletionView()
                            .frame(height: 300)
                    }
                    
                    Button("reload") {
                        Task {
                            await animationManager.handleButtonPressWithAnimation()
                        }
                    }
                    .disabled(AnimationManager.shared.isLoading)
                    
                    // bottom section - UV plot
                    UVIndexView()
                }
                .padding()
            }.tabItem {
                Image(systemName: "house")
                Text("Main page")
            }
            
            //  MARK: 2nd tab - debugging values
            ScrollView {
                VStack {
                    let envData = SharedDataManager.shared.getEnvironmentData()
                    let useData = SharedDataManager.shared.getUserData()
                    let uiFunctions = UIDisplayFunctions()
                    let nextTimeString = uiFunctions.displayNextTime()
                    
                    Text("For Fitzpatrick skin type \(useData.skinType), using SPF \(useData.spfUsed);")
                    Text("located latitude \(envData.latitude), longitude \(envData.longitude)")
                    Text("\nsunMax at \(envData.sunmaxTime)")
                    Text("sunSet at \(envData.sunsetTime)")
                    Text("\nuv now \(envData.uv), reapply after \(envData.minToReapp) min")
                    Text("at \(envData.nextTime), or simply put, \(nextTimeString)")
                    Text("SPF recommended is \(uiFunctions.convertToSPFRecommendation(envData.spfRecm))")
                    
                    Button("old handle button press") {
                        //  MARK: ***archive this function later
                        StateManager.shared.oldhandleButtonPress()
                        updateButtonState()
                    }
                    .disabled(!canPressButton)
                    
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
                .onReceive(timeZoneObserver.$timeZoneChanged) { changed in
                    if changed {
                        print("Time zone change received in App's view")
                        StateManager.shared.handleTimeZoneChange()
                        updateButtonState()
                    }
                }
                .onAppear {
                    updateButtonState()
                    if isFirstLaunch() {
                        print("first ever launch detected")
                        StateManager.shared.handleFirstOpen()
                    } else {
                        print("regular launch detected")
                    }
                }
            }.tabItem {
                Image(systemName: "wrench.and.screwdriver.fill")
                Text("Display Values")
            }

            //  MARK: 3rd designed user profile
            NavigationView {
                ScrollView {
                    VStack(spacing: 20) {
                        //  top section: name
                        VStack {
                            if isEditingName {
                                TextField("Name", text: $userData.name)
                                    .font(.largeTitleCustom)
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
                                .font(.captionCustom)
                                .foregroundColor(.textSecondary)
                        }
                        .padding()
                        
                        //  middle section: background image
                        Image("regular")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                        
                        //  bottom section: info field
                        VStack(spacing: 20) {
                            ForEach([
                                ("burns", userData.burnLikeliness.rawValue.capitalized, ProfileEditView.ProfileItemType.burn),
                                ("tans", userData.tanLikeliness.rawValue.capitalized, ProfileEditView.ProfileItemType.tan),
                                ("foundation", userData.foundationShade.rawValue.capitalized, ProfileEditView.ProfileItemType.foundation),
                                ("SPF", String(userData.spfUsed), ProfileEditView.ProfileItemType.spf)
                            ], id: \.0) { title, value, itemType in
                                NavigationLink(
                                    destination: ProfileEditView(userData: $userData, itemType: itemType)
                                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                                ) {
                                    ProfileItem(title: title, value: value)
                                }
                            }
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                    }
                    .padding()
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
        .overlay(
            FloatingButton() {
                print("Button pressed!")
            }
        )
    }
    
    private func updateButtonState() {
        canPressButton = StateManager.shared.canPressButton()
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

// HOWTO: Immediate fetch and update lat and long
//SharedDataManager.shared.fetchAndUpdateEnvironmentData(latitude: lat, longitude: lon) { error in
//    if let error = error {
//        print("Failed to fetch and update: \(error)")
//    } else {
//        print("Successfully fetched and updated environment data")
//    }
//}

// HOWTO: In your background fetch handler
//func performBackgroundFetch() {
//    let currentLocation = getCurrentLocation() // You'd need to implement this
//    SharedDataManager.shared.fetchAndUpdateEnvironmentData(latitude: currentLocation.latitude, longitude: currentLocation.longitude) { error in
//        // Handle any errors, complete the background task
//    }
//}
