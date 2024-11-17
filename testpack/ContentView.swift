import SwiftUI
import AVKit
import CachingPlayerItem

struct ContentView: View {
    @State private var player: AVPlayer?
   // private let playerDelegate = PlayerDelegate()
    
    let videoURLString = "https://storage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4"
    
    //body with player and on appear it should run loadVideo and on disappear the player if active should pause
    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                loadVideo()
            }
            .onDisappear {
                player?.pause()
                player = nil // Release the player
            }
            .frame(height: 300)
        
        Button("Delete Cache") {
            deleteCache()
            
            
            //another if statement that checks if the cache directory
            

            
        }

    }
    
    private func loadVideo() {
        //acts as an if statements setting url to the videourl
        guard let url = URL(string: videoURLString) else { return }
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
        
        
        player?.automaticallyWaitsToMinimizeStalling = true
        //When set to true, it allows the player to wait for enough media data to be buffered before starting playback, helping to minimize interruptions (or "stalls") during playback
        
        player?.play()
    }
    
    
    
    
    
    private func deleteCache() {
        let fileManager = FileManager.default
        
        // Get the cache directory URL
        guard let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            print("Could not find cache directory")
            return
        }
        
        do {
            // Get the contents of the cache directory
            let cachedFiles = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            
            // Loop through and delete each cached file
            for fileURL in cachedFiles {
                do {
                    try fileManager.removeItem(at: fileURL)
                    print("Deleted file: \(fileURL.lastPathComponent)")
                } catch {
                    print("Error deleting file \(fileURL.lastPathComponent): \(error.localizedDescription)")
                }
            }
        } catch {
            print("Error fetching cache directory contents: \(error.localizedDescription)")
        }
    }
}
    


/*
 This was to make sure I could set my own printing to make sure it was downloading (thats why the delegate function is set above too (commented out)).
 
 class PlayerDelegate: NSObject, CachingPlayerItemDelegate {
    func playerItem(_ playerItem: CachingPlayerItem, didFinishDownloadingFileAt filePath: String) {
        print("Finished downloading file at: \(filePath)")
    }

    func playerItem(_ playerItem: CachingPlayerItem, didDownloadBytesSoFar bytesDownloaded: Int, outOf bytesExpected: Int) {
        print("Downloaded \(bytesDownloaded) bytes out of \(bytesExpected)")
    }

    func playerItem(_ playerItem: CachingPlayerItem, downloadingFailedWith error: Error) {
        print("Downloading failed with error: \(error.localizedDescription)")
    }

    func playerItemReadyToPlay(_ playerItem: CachingPlayerItem) {
        print("Player item is ready to play")
    }

    func playerItemDidFailToPlay(_ playerItem: CachingPlayerItem, withError error: Error?) {
        print("Player item failed to play with error: \(error?.localizedDescription ?? "Unknown error")")
    }

    func playerItemPlaybackStalled(_ playerItem: CachingPlayerItem) {
        print("Playback stalled")
    }
}
*/
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
