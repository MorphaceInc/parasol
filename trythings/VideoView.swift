import SwiftUI
import AVKit


struct VideoView: View {
    @ObservedObject var videoManager : VideoManager
    //inherited by a parent function, so you use ObservedObject for swift to watch object and update view if changes
    @State var video: Video //fields that will update if changed 
    @State private var player = AVPlayer()
    @State var progressValue : Int =  0
   @State var timer : Timer? = nil

    var body: some View {
        ProgressBarView(value: $progressValue, video: $video)
     
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
                        self.startProgress()
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
                    nextVid()

                    
                }
            
            
        }
    }
    func nextVid(){
        let vid=videoManager.getNextVideo()
        if let unwrappedVideo = vid {
            video = unwrappedVideo
        }
        if let link = vid?.videoFiles.first?.link,
           let url = URL(string: link) {
            player = AVPlayer(url: url)
            player.play()
            self.startProgress()

        }

    }
    func startProgress(){
            resetProgress()
            self.timer = Timer.scheduledTimer(withTimeInterval: ProgressBarValue.intervalTime, repeats: true, block: { (Timer) in
                self.progressValue = self.progressValue+1
                if self.progressValue >= video.duration{
                    Timer.invalidate()
                    nextVid()
                }
            })
        
    }
    
    func resetProgress(){
        self.progressValue = 0
       timer?.invalidate()
    }
}


