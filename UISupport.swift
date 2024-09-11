//  Bookkeeping for rendering the view of user profile page
//      1. Color palette
//      2. For preview, edit, saving user profile data with expendable cards
//      3. For plotting UV intensity
//      4. For floating button

import SwiftUI
import SwiftData

//  MARK: 1. colors and fonts
extension Color {
    static let backgroundPrimary = Color(red: 0.98, green: 0.98, blue: 0.98)
    static let accentColor = Color(red: 0.35, green: 0.56, blue: 0.84)
    static let textPrimary = Color.black
    static let textSecondary = Color.gray
}

extension Font {
    static let largeTitleCustom = Font.system(size: 34, weight: .bold, design: .rounded)
    static let titleCustom = Font.system(size: 28, weight: .semibold, design: .rounded)
    static let headlineCustom = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let bodyCustom = Font.system(size: 17, weight: .regular, design: .rounded)
    static let captionCustom = Font.system(size: 14, weight: .regular, design: .rounded)
}

//  MARK: 2. preview, edit, and save user data
struct ProfileItem: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(value)
                    .font(.headlineCustom)
                    .foregroundColor(.textPrimary)
                Text(title)
                    .font(.captionCustom)
                    .foregroundColor(.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.accentColor)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
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
        case .foundation: return "What's your foundation shadee?"
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
            Text(title)
                .font(.titleCustom)
                .foregroundColor(.textPrimary)
                .padding()
            
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 200)
            
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
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                }
            }
        }
        .padding()
        .background(Color.backgroundPrimary)
        .navigationBarTitle("Edit Profile", displayMode: .inline)
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
        VStack {
            Text("UV Forecast Plot")
                .font(.title)
            
            if let firstForecastDate = envData.uvForecasts.first?.0 ,
               let lastForecastTime = envData.uvForecasts.last?.0 {
                
                if Calendar.current.isDate(Date(), inSameDayAs: firstForecastDate) && Date() <= lastForecastTime {
                    UVChartFunctions.plotEnhancedChart(dataPoints: envData.uvForecasts, smoothnessFactor: smoothnessFactor, currentDate: Date())
                        .frame(height: 300)
                        .padding()
                } else {
                    UVChartFunctions.plotBasicChart(dataPoints: envData.uvForecasts, smoothnessFactor: smoothnessFactor)
                        .frame(height: 300)
                        .padding()
                }
            }
        }
    }
}

//  MARK: 4. for reapplication button
struct FloatingButton: View {
    let nextTime = SharedDataManager.shared.getEnvironmentData().nextTime
    let pressAble = StateManager.shared.canPressButton()
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
        .position(x: UIScreen.main.bounds.width - 40, y: UIScreen.main.bounds.height - 100)
    }
    
    private var buttonColor: Color {
        if !pressAble {
            return .gray
        } else if Date() > nextTime {
            return .orange
        } else {
            return .blue
        }
    }
}
