import SwiftUI

struct ProgressBarView: View {
    @Binding var value: Int // Progress value (from 0 to video.duration)
    @Binding var video: Video // The video for the progress bar
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            //ZStack(alignment: .leading) {
                HStack {
                    // First section: background gray capsule
                    ZStack(alignment: .leading){
                        Capsule()
                            .frame(width: (UIScreen.main.bounds.width - 20) / 3, alignment: .topLeading)
                            .foregroundColor(Color.gray)
                        
                        Capsule()
                            .frame(width: ((UIScreen.main.bounds.width - 20) / 3) * CGFloat(value) / CGFloat(video.duration), alignment: .topLeading)
                            .foregroundColor(Color.black)
                            .animation(.linear, value: value)

                    }.frame(height: 3)
                    
                    ZStack(alignment: .leading){
                        
                        // Second section: background gray capsule
                        Capsule()
                            .frame(width: (UIScreen.main.bounds.width - 20) / 3, alignment: .center)
                            .foregroundColor(Color.gray)
                        Capsule()
                            .frame(width: ((UIScreen.main.bounds.width - 20) / 3) * CGFloat(value) / CGFloat(video.duration), alignment: .center)
                            .foregroundColor(Color.black)
                            .animation(.linear, value: value)

                    }.frame(height: 3)
                    // Third section: background gray capsule
                    
                    ZStack(alignment: .leading){
                        Capsule()
                            .frame(width: (UIScreen.main.bounds.width - 20) / 3, alignment: .topTrailing)
                            .foregroundColor(Color.gray)
                        
                        Capsule()
                            .frame(width: ((UIScreen.main.bounds.width - 20) / 3) * CGFloat(value) / CGFloat(video.duration), alignment: .topTrailing)
                            .foregroundColor(Color.black)
                            .animation(.linear, value: value)

                    }.frame(height: 3)
                }
                
            
                
            
        }
    }
    
    func percentage(value: Int) -> String {
        let value = Double(value)
        let v = (100.0 / Double(video.duration)) * value
        let intValue = Int(ceil(v))
        return "\(intValue) %"
    }
}
