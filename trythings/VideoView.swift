import SwiftUI
<<<<<<< Updated upstream
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
=======
import CachingPlayerItem
import AVKit

struct VideoView: View {
    @ObservedObject var videoManager: VideoManager
    @State var video: Video
    @State private var player = AVPlayer()
    @State var progressValue: Int = 0
    @State var timer: Timer? = nil
    @State var videoNum: Int = 0
    @Environment(\.presentationMode) var presentationMode // environment object that keeps track of what is shown

    var body: some View {
        ProgressBarView(value: $progressValue, video: $video, videoNum: $videoNum)

        ZStack {
            VideoPlayer(player: player)
                .edgesIgnoringSafeArea(.all)
                .disabled(true)
                .onAppear {
>>>>>>> Stashed changes
                    if let link = video.videoFiles.first?.link,
                       let url = URL(string: link) {
                        player = AVPlayer(url: url)
                        player.play()
                        self.startProgress()
<<<<<<< Updated upstream
                       videoManager.setCurrInd(currind: video.pos)
=======
                        videoManager.setCurrInd(currind: video.pos)
>>>>>>> Stashed changes
                    }
                }
                .onDisappear {
                    player.pause() // Pause when view disappears
<<<<<<< Updated upstream
                }
                
=======
                    self.resetProgress() // Reset progress bar to 0
                }

>>>>>>> Stashed changes
            // Tap gesture to skip forward
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
<<<<<<< Updated upstream
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


=======
                    player.pause() // Pause current video
                    nextVid() // Switch to the next video
                }
        }
    }

   
    func nextVid() {
        if(videoNum == 2){
            self.presentationMode.wrappedValue.dismiss() // dismissing current view once the text is tabbed
            return
        }
        let vid = videoManager.getNextVideo()
        if let unwrappedVideo = vid {
            video = unwrappedVideo
        }
        videoNum+=1
        
        if let link = vid?.videoFiles.first?.link,
           
           let url = URL(string: link) {
            
            //here
            let fileName = url.lastPathComponent
            //get just the video name
            
            let fileManager = FileManager.default
            //make a file manager object
            guard let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
                print("Could not find cache directory")
                return
            }
            //another if statement that checks if the cache directory
            
            let cachedFilePath = cacheDirectory.appendingPathComponent(fileName)
            //add the filename to the cache directory
            
            //if the cachedfilepath exists (video already cached), then the set the player item (set it to the existing filePathURL)
            if fileManager.fileExists(atPath: cachedFilePath.path) {
                let playerItem = CachingPlayerItem(filePathURL: cachedFilePath)
              //  playerItem.delegate = playerDelegate
                
                //make the player
                player = AVPlayer(playerItem: playerItem)
            } else {
                //otherwise specify the path to be a string representation of the file location
                let playerItem = CachingPlayerItem(url: url, saveFilePath: cachedFilePath.path, customFileExtension: "mp4")
             //   playerItem.delegate = playerDelegate
                player = AVPlayer(playerItem: playerItem)
            }
            
            
            //player.automaticallyWaitsToMinimizeStalling = true
            //When set to true, it allows the player to wait for enough media data to be buffered before starting playback, helping to minimize interruptions (or "stalls") during playback
            
            player.play()
            
            
            
            //here
            self.startProgress()
        }
    }

    
    func startProgress() {
        resetProgress()
        self.timer = Timer.scheduledTimer(withTimeInterval: ProgressBarValue.intervalTime, repeats: true, block: { (Timer) in
            self.progressValue = self.progressValue + 1
            if self.progressValue >= video.duration {
                Timer.invalidate() // Stop the timer when the video reaches its duration
                nextVid() // Move to the next video
            }
        })
    }

    func resetProgress() {
        self.progressValue = 0
        timer?.invalidate() // Invalidate the previous timer if it exists
    }
}
>>>>>>> Stashed changes
