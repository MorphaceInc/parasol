import SwiftUI
import AVKit

struct ContentView: View {
    @State private var videoURL: URL?
    
    var body: some View {
        VStack {
            if let videoURL = videoURL {
                // Show the video player if the video URL is available
                VideoPlayer(player: AVPlayer(url: videoURL))
                    .frame(height: 300)
                    .padding()
            } else {
                Text("Loading video...")
                    .font(.headline)
                    .padding()
            }
        }
        .onAppear {
            // Fetch the video URL when the view appears
            fetchVideoURL()
        }
    }
    
    
    private func get_date(){
        
        let currentDate = Date()

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"

        let formattedDate = dateFormatter.string(from: currentDate)

    }
    
    private func fetchVideoURL() {
        // Replace with your own URL to the API that returns the signed video URL
        let videoURLString = "https://kcvbql2ezl.execute-api.ca-central-1.amazonaws.com/dev/videos?video_name=20241101_1.mp4"
        
        if let url = URL(string: videoURLString) {
            // Fetch video URL from the API
            let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
                if let error = error {
                    print("Error: \(error.localizedDescription)")
                    return
                }
                
                if let data = data {
                    // Decode the JSON response to extract the video URL
                    do {
                        let decoder = JSONDecoder()
                        let response = try decoder.decode(VideoResponse.self, from: data)
                        
                        // Check if the URL is valid and set the video URL
                        if let videoURLString = response.body, let videoURL = URL(string: videoURLString) {
                            DispatchQueue.main.async {
                                self.videoURL = videoURL
                            }
                        } else {
                            print("Invalid video URL")
                        }
                    } catch {
                        print("Failed to decode JSON: \(error.localizedDescription)")
                    }
                }
            }
            
            task.resume()
        }
    }
}

// Define the struct to decode the JSON response
struct VideoResponse: Decodable {
    var statusCode: Int
    var body: String?
}

