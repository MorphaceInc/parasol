//  Bookkeeping for rendering the view of user profile page
//      1. Color palette
//      2. For preview, edit, saving user profile data with cards
//      3. For elements on the UV dashboard

import SwiftUI
import SwiftData

//  MARK: 1. colors and fonts
extension Color {
    static let backgroundPrimary = Color(red: 1, green: 1, blue: 1)
    static let textAccent = Color(red: 0.180, green: 0.423, blue: 0.553)
    static let textPrimary = Color(red: 0.455, green: 0.701, blue: 0.969)
}

extension Font {
    static let largeTitleCustom = Font.system(size: 52, weight: .bold)
    static let headlineCustom = Font.system(size: 18, weight: .regular)
    static let titleCustom = Font.system(size: 14, weight: .semibold)
    static let bodyCustom = Font.system(size: 14, weight: .regular)
    static let captionCustom = Font.system(size: 14, weight: .regular)
}

struct DottedDivider: View {
    var isHorizontal = false
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let start = CGPoint(x: isHorizontal ? 0 : geometry.size.width / 2,
                                    y: isHorizontal ? geometry.size.height / 2 : 0)
                let end = CGPoint(x: isHorizontal ? geometry.size.width : geometry.size.width / 2,
                                  y: isHorizontal ? geometry.size.height / 2 : geometry.size.height)
                path.move(to: start)
                path.addLine(to: end)
            }
            .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [1.5]))
            .foregroundColor(.textPrimary.opacity(0.2))
        }
        .frame(width: isHorizontal ? nil : 1, height: isHorizontal ? 1 : nil)
    }
}

struct CustomTabViewAppearance: ViewModifier {
    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.shadowColor = .clear
        
        let selectedColor = UIColor(red: 0.180, green: 0.423, blue: 0.553, alpha: 1.0)
        let unselectedColor = UIColor(red: 0.455, green: 0.701, blue: 0.969, alpha: 1.0)
        
        appearance.stackedLayoutAppearance.selected.iconColor = selectedColor
        appearance.stackedLayoutAppearance.normal.iconColor = unselectedColor
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        
        UITabBar.appearance().tintColor = selectedColor
        UITabBar.appearance().unselectedItemTintColor = unselectedColor
    }
    
    func body(content: Content) -> some View {
        content
    }
}

extension View {
    func customTabViewAppearance() -> some View {
        self.modifier(CustomTabViewAppearance())
    }
}

//  MARK: 2. preview, edit, and save user data
struct midProfileElement: View {
    @Binding var currentImageName: String
    let geometry: GeometryProxy
    
    var body: some View {
        Image(currentImageName)
            .resizable()
            .scaledToFit()
            .frame(width: geometry.size.width * 0.8, height: geometry.size.height * 0.35)
            .animation(.easeInOut, value: currentImageName)
    }
}

struct botProfileElement: View {
    @Binding var userData: UserData
    @Binding var currentPage: Page
    @Binding var currentImageName: String
    let geometry: GeometryProxy
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.white)
                    .shadow(color: Color.blue.opacity(0.15), radius: 5.7, x: 0, y: 5)
                
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.textPrimary.opacity(0.05))
                
                VStack {
                    if currentPage == .regular {
                        HomeProfileView(userData: $userData, currentPage: $currentPage, currentImageName: $currentImageName)
                    } else if currentPage == .spf {
                        SPFInputView(userData: $userData, currentPage: $currentPage, currentImageName: $currentImageName)
                    } else {
                        OptionSelectionView(userData: $userData, currentPage: $currentPage, currentImageName: $currentImageName)
                    }
                }
                .padding()
            }
            .frame(width: geometry.size.width * 0.75)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .frame(height: geometry.size.height * 0.35)
        .animation(.easeInOut, value: currentPage)
    }
}

struct HomeProfileView: View {
    @Binding var userData: UserData
    @Binding var currentPage: Page
    @Binding var currentImageName: String
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                optionButton(for: .burn)
                DottedDivider()
                optionButton(for: .tan)
            }
            DottedDivider(isHorizontal: true)
            HStack(spacing: 0) {
                optionButton(for: .foundation)
                DottedDivider()
                optionButton(for: .spf)
            }
        }
    }
    
    private func optionButton(for option: RegularOption) -> some View {
        Button(action: {
            selectRegularOption(option)
        }) {
            VStack(alignment: .center, spacing: 2) {
                if let prefix = option.prefix {
                    Text(prefix)
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.textPrimary)
                }
                Text(getCurrentValue(for: option))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.textAccent)
                Text(option.title)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.textPrimary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private func selectRegularOption(_ option: RegularOption) {
        switch option {
        case .burn:
            currentPage = .burn
        case .tan:
            currentPage = .tan
        case .foundation:
            currentPage = .foundation
        case .spf:
            currentPage = .spf
        }
        currentImageName = option.rawValue.lowercased()
    }
    
    private func getCurrentValue(for option: RegularOption) -> String {
        switch option {
        case .burn:
            return userData.burnLikeliness.rawValue.capitalized
        case .tan:
            return userData.tanLikeliness.rawValue.capitalized
        case .foundation:
            return userData.foundationShade.rawValue.capitalized
        case .spf:
            return "\(userData.spfUsed)"
        }
    }
}

struct OptionSelectionView: View {
    @Binding var userData: UserData
    @Binding var currentPage: Page
    @Binding var currentImageName: String
    
    var body: some View {
        VStack(spacing: 5) {
            Text(getPromptText())
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.textAccent)
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)
            
            ForEach(1...5, id: \.self) { option in
                Button(action: {
                    selectOption(option)
                }) {
                    Text(getOptionText(for: option))
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(.textPrimary)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
    }
    
    private func selectOption(_ option: Int) {
        switch currentPage {
        case .burn:
            userData.burnLikeliness = BurnLikeliness.allCases[option - 1]
        case .tan:
            userData.tanLikeliness = TanLikeliness.allCases[option - 1]
        case .foundation:
            userData.foundationShade = FoundationShade.allCases[option - 1]
        default:
            break
        }
        userData.calculateSkinType()
        SharedDataManager.shared.saveUserData(userData)
        currentPage = .regular
        currentImageName = "regular"
    }
    
    private func getPromptText() -> String {
        switch currentPage {
        case .burn:
            return "How easily do you burn?"
        case .tan:
            return "How easily do you tan?"
        case .foundation:
            return "What shade is your skin?"
        case .spf:
            return "What SPF do you use?"
        default:
            return ""
        }
    }
    
    private func getOptionText(for option: Int) -> String {
        switch currentPage {
        case .burn:
            return BurnLikeliness.allCases[option - 1].rawValue
        case .tan:
            return TanLikeliness.allCases[option - 1].rawValue
        case .foundation:
            return FoundationShade.allCases[option - 1].rawValue
        default:
            return "Option \(option)"
        }
    }
}

struct SPFInputView: View {
    @Binding var userData: UserData
    @Binding var currentPage: Page
    @Binding var currentImageName: String
    
    var body: some View {
        VStack {
            Text("What's your current sunscreen SPF?")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.textAccent)
                .multilineTextAlignment(.center)
            HStack {
                Text("SPF: ")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.textPrimary)
                TextField("Enter SPF", value: $userData.spfUsed, formatter: NumberFormatter())
                    .keyboardType(.numberPad)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.textPrimary)
                Button("Done") {
                    SharedDataManager.shared.saveUserData(userData)
                    currentPage = .regular
                    currentImageName = "regular"
                }
                .font(.system(size: 18, weight: .regular))
                .foregroundColor(.textPrimary)
            }
            .padding()
        }
    }
}

enum Page {
    case regular, burn, tan, foundation, spf
}

enum RegularOption: String, CaseIterable {
    case burn, tan, foundation, spf
    
    var prefix: String? {
        switch self {
        case .foundation, .spf: return "uses"
        default: return nil
        }
    }
    
    var title: String { rawValue }
}

//  MARK: 3. for elements on the UV dashboard
struct dashboardFloatElement: View {
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.white)
                    .shadow(color: Color.blue.opacity(0.15), radius: 5.7, x: 0, y: 5)
                
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.textPrimary.opacity(0.05))
                
                VStack {
                    HStack(alignment: .center, spacing: 4) {
                        Spacer(minLength: geometry.size.width * 0.1)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("next")
                                .font(.system(size: 18, weight: .regular))
                                .foregroundColor(.textPrimary)
                            Text("apply")
                                .font(.system(size: 18, weight: .regular))
                                .foregroundColor(.textPrimary)
                        }.frame(width: geometry.size.width * 0.2)
                        
                        Text(UIDisplayFunctions().displayNextTime())
                            .font(Font.system(size: 47, weight: .bold))
                            .foregroundColor(.textAccent)
                            .frame(width: geometry.size.width * 0.8)
                    }
                    .frame(height: geometry.size.height * 0.7)
                    
                    DottedDivider(isHorizontal: true)
                    
                    HStack {
                        HStack(spacing: 4) {
                            Image(systemName: "lightspectrum.horizontal")
                                .foregroundColor(.textPrimary)
                            Text("UVI \(SharedDataManager.shared.getEnvironmentData().uv, specifier: "%.1f")")
                                .font(.system(size: 18, weight: .regular))
                                .foregroundColor(.textPrimary)
                        }
                        .frame(width: geometry.size.width / 2)
                        
                        DottedDivider()
                        
                        Button(action: {
                            LocationService().getCurrentLocation {_ in}
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "location.circle")
                                    .foregroundColor(.textPrimary)
                                Text(SharedDataManager.shared.getEnvironmentData().cityName)
                                    .font(.system(size: 18, weight: .regular))
                                    .foregroundColor(.textPrimary)
                            }
                            .frame(width: geometry.size.width / 2)}
                    }
                    .frame(height: geometry.size.height * 0.3)
                }
            }
            .frame(width: geometry.size.width, alignment: .top)
        }
    }
}

struct UVIndexView: View {
    let envData = SharedDataManager.shared.getEnvironmentData()
    @State private var smoothnessFactor: CGFloat = 0.45
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .center) {
                Spacer(minLength: 30)
                DottedDivider(isHorizontal: true)
                
                Text("Based on your skin type and")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.textPrimary)
                
                Text("the sun intensity on \(envData.uvForecasts.first?.0 ?? Date(), format: .dateTime.month(.abbreviated).day().weekday()),")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.textPrimary)
                
                Text("use \(UIDisplayFunctions().convertToSPFRecommendation())")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.textAccent)
                
                Text("to protect your skin.")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.textPrimary)
                
                DottedDivider(isHorizontal: true)
                Spacer(minLength: 30)
                
                HStack(spacing: 4) {
                    Image(systemName: "lightspectrum.horizontal")
                        .foregroundColor(.textPrimary)
                    
                    Text("UV Index")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.textPrimary)
                }
                
                if let firstForecastDate = envData.uvForecasts.first?.0 ,
                   let lastForecastTime = envData.uvForecasts.last?.0 {
                    
                    if Calendar.current.isDate(Date(), inSameDayAs: firstForecastDate) && firstForecastDate <= Date() && Date() <= lastForecastTime {
                        UVChartFunctions.plotEnhancedChart(dataPoints: envData.uvForecasts, smoothnessFactor: smoothnessFactor, currentDate: Date())
                            .frame(height: geometry.size.height * 0.5)
                            .frame(width: geometry.size.width * 0.9, alignment: .center)
                    } else {
                        UVChartFunctions.plotBasicChart(dataPoints: envData.uvForecasts, smoothnessFactor: smoothnessFactor)
                            .frame(height: geometry.size.height * 0.5)
                            .frame(width: geometry.size.width * 0.9, alignment: .center)
                    }
                }
                Spacer()
            }
            .padding(.bottom, geometry.size.height * 0.05)
        }
    }
}

struct FloatingButton: View {
    @State private var pressAble: Bool = false
    var action: () -> Void
    
    var body: some View {
        Button(action: {
            if pressAble {
                action()
            }
        }) {
            Image(systemName: "plus")
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(buttonColor)
                )
                .shadow(radius: 5)
        }
        .disabled(!pressAble)
        .onAppear {
            pressAble = StateManager.shared.canPressButton()
        }
        .position(x: UIScreen.main.bounds.width - 60, y: UIScreen.main.bounds.height - 200)
    }
    
    private var buttonColor: Color {
        if !pressAble {
            return .gray
        } else if Date() > SharedDataManager.shared.getEnvironmentData().nextTime {
            return .orange
        } else {
            return .blue
        }
    }
}
