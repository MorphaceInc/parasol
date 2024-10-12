import SwiftUI
import AVKit


struct VideoView: View {
    @StateObject var videoManager = VideoManager()
    var video: Video
    @State private var player = AVPlayer()
    
    var body: some View {

        ZStack {
            VideoPlayer(player: player)
                .edgesIgnoringSafeArea(.all)// Ignore safe areas
                .disabled(/*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/)
                .onAppear {
                    // Unwrapping optional
                    if let link = video.videoFiles.first?.link,
                       let url = URL(string: link) {
                        player = AVPlayer(url: url)
                        player.play()
                        videoManager.setCurrInd(currind: video.pos)
                    }
                }
                .onDisappear {
                    player.pause() // Pause when view disappears
                }
                
            
            // Tap gesture to skip forward
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    if let link = videoManager.getNextVideo()?.videoFiles.first?.link,
                       let url = URL(string: link) {
                        player = AVPlayer(url: url)
                        player.play()
                    }

                    
                }
            
            
        }
    }
}

struct VideoView_Previews: PreviewProvider {
    static var previews: some View {
        VideoView(video: previewVideo) // Replace with your preview video object
    }
}
