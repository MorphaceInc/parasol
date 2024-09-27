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
    static let titleCustom = Font.system(size: 17, weight: .semibold)
    static let bodyCustom = Font.system(size: 17, weight: .regular)
    static let captionCustom = Font.system(size: 14, weight: .regular)
}

//  MARK: 2. preview, edit, and save user data
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

struct ProfileItemButton: View {
    let title: String
    let value: String
    let itemType: ProfileEditView.ProfileItemType
    @Binding var userData: UserData
    var prefix: String?
    
    var body: some View {
        NavigationLink(
            destination: ProfileEditView(userData: $userData, itemType: itemType)
                .transition(.opacity)
        ) {
            VStack(alignment: .center) {
                if let prefix = prefix {
                    Text(prefix)
                        .font(Font.system(size: 22, weight: .regular))
                        .foregroundColor(.textPrimary)
                }
                Text(value)
                    .font(Font.system(size: 22, weight: .bold))
                    .foregroundColor(.textAccent)
                Text(title)
                    .font(Font.system(size: 22, weight: .regular))
                    .foregroundColor(.textPrimary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ProfileEditView: View {
    @Binding var userData: UserData
    @Environment(\.presentationMode) var presentationMode
    let itemType: ProfileItemType
    
    enum ProfileItemType {
        case burn, tan, foundation, spf
    }
    
    var title: String {
        switch itemType {
        case .burn: return "How easily do you get sunburned?"
        case .tan: return "How easily do you tan?"
        case .foundation: return "What's your foundation shade?"
        case .spf: return "What's your sunscreen SPF?"
        }
    }
    
    var options: [String] {
        switch itemType {
        case .burn:
            return ["Always", "Easily", "Sometimes", "Rarely", "Never"]
        case .tan:
            return ["Never", "Rarely", "Sometimes", "Easily", "Always"]
        case .foundation:
            return ["Light", "Medium", "Tan", "Dark", "Deep"]
        case .spf:
            return ["15", "30", "50", "100"]
        }
    }
    
    var imageName: String {
        switch itemType {
        case .burn: return "burnt"
        case .tan: return "tanned"
        case .foundation: return "foundation"
        case .spf: return "spf"
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            VStack {
                Text(userData.name)
                    .font(.largeTitleCustom)
                    .foregroundColor(.textPrimary)
                Text("skin profile")
                    .font(.headlineCustom)
                    .foregroundColor(.textPrimary)
            }
            
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 200, height: 200)
            
            ZStack{
                VStack(spacing: 0) {
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.white)
                        .shadow(color: Color.blue.opacity(0.25), radius: 5.7, x: 0, y: 5)
                }
                
                VStack(spacing: 0) {
                    Text(title)
                        .font(.titleCustom)
                        .foregroundColor(.textPrimary)
                        .padding()
                    
                    ForEach(options, id: \.self) { option in
                        Button(action: {
                            updateUserData(option)
                            withAnimation(.easeInOut(duration: 0.3)) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }) {
                            Text(option)
                                .font(.bodyCustom)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .background(Color.white)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(20)
                .background(Color.textPrimary.opacity(0.07))
                .cornerRadius(25)
            }
            .padding(40)
        }
        .background(Color.backgroundPrimary)
        .navigationBarHidden(true)
    }
    
    func updateUserData(_ newValue: String) {
        switch itemType {
        case .burn:
            userData.burnLikeliness = BurnLikeliness(rawValue: newValue.lowercased()) ?? .sometimes
            userData.calculateSkinType()
        case .tan:
            userData.tanLikeliness = TanLikeliness(rawValue: newValue.lowercased()) ?? .sometimes
            userData.calculateSkinType()
        case .foundation:
            userData.foundationShade = FoundationShade(rawValue: newValue.lowercased()) ?? .medium
            userData.calculateSkinType()
        case .spf:
            userData.spfUsed = Int(newValue) ?? 15
        }
        SharedDataManager.shared.saveUserData(userData)
    }
}

//  MARK: 3. for plotting UV index
struct UVIndexView: View {
    let envData = SharedDataManager.shared.getEnvironmentData()
    @State private var smoothnessFactor: CGFloat = 0.45
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("\(UIDisplayFunctions().convertToSPFRecommendation()) is recommended for today/tomorrow's sun intensity")
                .font(.titleCustom)
            
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
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 5)
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
