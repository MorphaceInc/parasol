//  Bookkeeping for rendering the view of user profile page
//      1. Color palette
//      2. For preview, edit, saving user profile data with expendable cards
//      3. For plotting UV intensity
//      4. For floating button

import SwiftUI
import SwiftData

//  MARK: 1. colors and fonts
extension Color {
    static let backgroundPrimary = Color(red: 1, green: 1, blue: 1)
    static let textAccent = Color.black
    static let textPrimary = Color(red: 0.4, green: 0.6, blue: 0.8)
}

extension Font {
    static let largeTitleCustom = Font.system(size: 52, weight: .bold)
    static let headlineCustom = Font.system(size: 27, weight: .regular)
    static let titleCustom = Font.system(size: 14, weight: .semibold)
    static let bodyCustom = Font.system(size: 14, weight: .regular)
    static let captionCustom = Font.system(size: 14, weight: .regular)
}

//  MARK: 2. preview, edit, and save user data
struct midProfileElement: View {
    @Binding var currentImageName: String
    let geometry: GeometryProxy
    
    var body: some View {
        Image(currentImageName)
            .resizable()
            .scaledToFit()
            .frame(width: geometry.size.width * 0.8, height: geometry.size.height * 0.3)
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
                    .shadow(color: Color.blue.opacity(0.25), radius: 5.7, x: 0, y: 5)
                
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.textPrimary.opacity(0.07))
                
                VStack {
                    if currentPage == .regular {
                        HomeProfileView(userData: $userData, currentPage: $currentPage, currentImageName: $currentImageName)
                    } else if currentPage == .spf {
                        SPFInputView(userData: $userData, currentPage: $currentPage)
                    } else {
                        OptionSelectionView(userData: $userData, currentPage: $currentPage, currentImageName: $currentImageName)
                    }
                }
                .padding()
            }
            .frame(width: geometry.size.width * 0.8)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
        }
        .frame(height: geometry.size.height * 0.3)
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
            VStack(alignment: .center) {
                if let prefix = option.prefix {
                    Text(prefix)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.textPrimary)
                }
                Text(getCurrentValue(for: option))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.textAccent)
                Text(option.title)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.textPrimary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
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

struct SPFInputView: View {
    @Binding var userData: UserData
    @Binding var currentPage: Page
    
    var body: some View {
        HStack {
            Text("SPF:")
            TextField("Enter SPF", value: $userData.spfUsed, formatter: NumberFormatter())
                .keyboardType(.numberPad)
            Button("Done") {
                SharedDataManager.shared.saveUserData(userData)
                currentPage = .regular
            }
        }
        .padding()
    }
}

struct OptionSelectionView: View {
    @Binding var userData: UserData
    @Binding var currentPage: Page
    @Binding var currentImageName: String
    
    var body: some View {
        VStack {
            ForEach(1...5, id: \.self) { option in
                Button(action: {
                    selectOption(option)
                }) {
                    Text(getOptionText(for: option))
                        .padding()
                        .frame(maxWidth: .infinity)
                }
            }
        }
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

enum Page {
    case regular, burn, tan, foundation, spf
}

enum RegularOption: String, CaseIterable {
    case burn = "burn"
    case tan = "tan"
    case foundation = "foundation"
    case spf = "spf"
    
    var prefix: String? {
        switch self {
        case .burn:
            return nil
        case .tan:
            return nil
        case .foundation:
            return "uses"
        case .spf:
            return "uses"
        }
    }
    
    var title: String {
        return self.rawValue
    }
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
            .foregroundColor(.blue.opacity(0.2))
        }
        .frame(width: isHorizontal ? nil : 1, height: isHorizontal ? 1 : nil)
    }
}

//  MARK: 3. for plotting UV index
struct UVIndexView: View {
    let envData = SharedDataManager.shared.getEnvironmentData()
    @State private var smoothnessFactor: CGFloat = 0.45
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(UIDisplayFunctions().convertToSPFRecommendation()) is recommended for today/tomorrow's sun intensity")
                .font(.bodyCustom)
                .foregroundColor(.textPrimary)
            
            if let firstForecastDate = envData.uvForecasts.first?.0 ,
               let lastForecastTime = envData.uvForecasts.last?.0 {
                
                if Calendar.current.isDate(Date(), inSameDayAs: firstForecastDate) && firstForecastDate <= Date() && Date() <= lastForecastTime {
                    UVChartFunctions.plotEnhancedChart(dataPoints: envData.uvForecasts, smoothnessFactor: smoothnessFactor, currentDate: Date())
                        .frame(height: 220)
                        .frame(maxWidth: .infinity)
                } else {
                    UVChartFunctions.plotBasicChart(dataPoints: envData.uvForecasts, smoothnessFactor: smoothnessFactor)
                        .frame(height: 220)
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(Color.textPrimary.opacity(0.07))
        .cornerRadius(25)
        //  MARK: *** bug *** shadow is for text, not for the background
        .shadow(color: Color.blue.opacity(0.25), radius: 5.7, x: 0, y: 5)
    }
}

//  MARK: 4. for reapplication button
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
