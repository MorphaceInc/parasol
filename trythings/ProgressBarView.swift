import SwiftUI

struct ProgressBarView: View {
    @Binding var value: Int // Progress value (from 0 to video.duration)
    @Binding var video: Video // The video for the progress bar
<<<<<<< Updated upstream
=======
    @Binding var videoNum: Int 
>>>>>>> Stashed changes
    
    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            //ZStack(alignment: .leading) {
<<<<<<< Updated upstream
                HStack {
=======
            HStack {
                
                if(videoNum==0){
>>>>>>> Stashed changes
                    // First section: background gray capsule
                    ZStack(alignment: .leading){
                        Capsule()
                            .frame(width: (UIScreen.main.bounds.width - 20) / 3, alignment: .topLeading)
                            .foregroundColor(Color.gray)
                        
                        Capsule()
                            .frame(width: ((UIScreen.main.bounds.width - 20) / 3) * CGFloat(value) / CGFloat(video.duration), alignment: .topLeading)
                            .foregroundColor(Color.black)
                            .animation(.linear, value: value)
<<<<<<< Updated upstream
=======
                        
                    }.frame(height: 3)
                    
                    ZStack(alignment: .leading){
                        
                        Capsule()
                            .frame(width: (UIScreen.main.bounds.width - 20) / 3, alignment: .center)
                            .foregroundColor(Color.gray)
                      
                        
                    }.frame(height: 3)
                    
                    ZStack(alignment: .leading){
                        Capsule()
                            .frame(width: (UIScreen.main.bounds.width - 20) / 3, alignment: .center)
                            .foregroundColor(Color.gray)

                    }.frame(height: 3)
                }else if(videoNum==1){
                    // First section: background gray capsule
                    ZStack(alignment: .leading){
                        Capsule()
                            .frame(width: (UIScreen.main.bounds.width - 20) / 3, alignment: .center)
                            .foregroundColor(Color.black)
>>>>>>> Stashed changes

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
<<<<<<< Updated upstream
=======
                        
                    }.frame(height: 3)
                    // Third section: background gray capsule
                    
                    ZStack(alignment: .leading){
                        Capsule()
                            .frame(width: (UIScreen.main.bounds.width - 20) / 3, alignment: .center)
                            .foregroundColor(Color.gray)

                    }.frame(height: 3)
                    
                }else if(videoNum==2){
                    // First section: background gray capsule
                    ZStack(alignment: .leading){
                        Capsule()
                            .frame(width: (UIScreen.main.bounds.width - 20) / 3, alignment: .center)
                            .foregroundColor(Color.black)

                    }.frame(height: 3)
                    
                    ZStack(alignment: .leading){
                        
                        Capsule()
                            .frame(width: (UIScreen.main.bounds.width - 20) / 3, alignment: .center)
                            .foregroundColor(Color.black)
>>>>>>> Stashed changes

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
<<<<<<< Updated upstream

                    }.frame(height: 3)
                }
                
=======
                        
                    }.frame(height: 3)
                    
                }
            }
>>>>>>> Stashed changes
            
                
            
        }
    }
    
    func percentage(value: Int) -> String {
        let value = Double(value)
        let v = (100.0 / Double(video.duration)) * value
        let intValue = Int(ceil(v))
        return "\(intValue) %"
    }
}
