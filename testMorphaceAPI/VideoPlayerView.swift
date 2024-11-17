import SwiftUI
import AVKit

struct VideoPlayerView: View {
    var video: Video
    
    var body: some View {
        VStack {
            // AVPlayer view to play the video
            VideoPlayer(player: AVPlayer(url: video.url))
                .frame(height: 300)
                .cornerRadius(10)
        }
        .padding()
    }
}
