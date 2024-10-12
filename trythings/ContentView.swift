import SwiftUI


struct ContentView: View {
    @StateObject var videoManager = VideoManager()
    var columns = [GridItem(.adaptive(minimum: 100), spacing: 20)]
    var body: some View {
        
        
        
        NavigationView {
            
            
            VStack() {
                // Gradient background that only spans above the text
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 255 / 255, green: 221 / 255, blue: 151 / 255),
                        .white
                    ]),
                    startPoint: .top,
                    endPoint: .bottom)
                .frame(height: 50) // Adjust height as needed
                .edgesIgnoringSafeArea(.all) // Ensures the gradient starts at the top of the screen
                
                
                ScrollView{
                    
                    
                    VStack {
                        HStack {
                            VStack {
                                Image("orange-profile") // Replace with your image name
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50) // Adjust size as needed
                            }
                            .padding(.leading, 10) // Adjust padding as needed
                            
                            VStack(alignment: .leading, spacing: 5) { // Adjust spacing if needed
                                Text("Good Morning, Stephanie")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundColor(.black)
                                
                                Text("Today")
                                    .font(.system(size: 30, weight: .medium))
                                    .foregroundColor(.black)
                            }
                            .padding(.leading, 10) // Adjust padding as needed
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Spacer() // Pushes content up
                        
                        
                    }.padding(.bottom, 60)
                    
                    HStack(alignment: .top, spacing: 20) { // Adjust spacing as needed
                        
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 204 / 255, green: 244 / 255, blue: 245 / 255))
                            .frame(width: 170, height: 120)
                            .padding(.leading, 20) // Adjust padding as needed
                        
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(red: 204 / 255, green: 244 / 255, blue: 245 / 255))
                            .frame(width: 170, height: 120)
                            .padding(.trailing, 20) // Adjust padding as needed
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    // Pushes the content to the top
                    
                    
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 204 / 255, green: 244 / 255, blue: 245 / 255))
                        .frame(width: 360, height: 190)
                        .padding(.top, 10)
                    
                    Divider() // Line separator
                        .background(Color.gray) // Adjust color as needed
                        .padding(.vertical, 20) // Adjust padding as needed
                    
                    VStack(alignment: .leading) { // Align text to leading
                        Text("Today's Insights")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.leading) // Align text within its frame
                    }
                    
                    
                    
                
                
                
                HStack(alignment: .top, spacing: 20) { // Adjust spacing as needed
                    
                    
                    if videoManager.videos.isEmpty {
                        ProgressView()
                    } else {
                        LazyVGrid(columns: columns, spacing: 20) {
                            var i: Int = 1
                            ForEach(videoManager.videos, id: \.id) {
                                video in
                                NavigationLink {
                                    VideoView(video: video)
                                } label: {
                                    ZStack{
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(red: 204 / 255, green: 244 / 255, blue: 208 / 255))
                                            .frame(width: 112, height: 120)
                                            .padding(.leading, 20)// Adjust padding as needed
                                            .padding(.trailing, 20)
                                        
                                        Text("Video")
                                            .font(.title)
                                            .foregroundColor(.black)
                                            .multilineTextAlignment(.center)
                                            .padding()
                                        
                                        
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
                    
                    
                    
                    
                
                
                
            }
        }.navigationViewStyle(.stack)
      
        
    }
    
   
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
