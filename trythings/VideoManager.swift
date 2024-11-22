<<<<<<< Updated upstream
//
//  VideoManager.swift
//  VideoFinder

import Foundation // A shared library shipped in the Swift toolchain, written in Swift. It provides the core implementation of many key types, including URL , Data , JSONDecoder , Locale , Calendar , and more

// An enumeration of the tags query our app offers (when watching video for pexels api you can have different enum cases.
//The type of the query is string and caseiterable indicates that you can access cases using .allcases
enum Query: String, CaseIterable {
    case nature, animals, people, ocean, food
    //here contains different cases.
}

class VideoManager: ObservableObject {
    //class Video Manager (instance of class can be made in different places).  (blueprint).... Classes have attributes, functions
    // ObservableObject means that the views that use it will reload as it changes, Published is for variables that do this
    

    @Published private(set) var videos: [Video] = []
    //
    
    @Published var selectedQuery: Query = .nature {
        didSet {
            Task.init {
                await findVideos(topic: selectedQuery)
                print("making request in didset")
            }
        }
    }
    
    @Published var currentIndex: Int = 0
    
    init() {
        Task.init {
            await findVideos(topic: selectedQuery)
            print("making request in init")
        }
    }
    
    func setCurrInd(currind : Int){
        currentIndex = currind
        print("thecurrindex change")
        print(currentIndex)
    }
    
    func getCurrInd() ->Int{
        return currentIndex
    }
    
    func getVideos() -> [Video] {
        return videos
    }
    
    func findVideos(topic: Query) async {
        do {
            guard let url = URL(string: "https://api.pexels.com/videos/search?query=\(topic)&per_page=10&orientation=portrait") else { fatalError("Missing URL") }
            var urlRequest = URLRequest(url: url)
            urlRequest.setValue("ybcKlkvxlyOXas1FACktwWwEUodUvMZ8DoPVvNYKWVqK2ZdOkeobL55d", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { fatalError("Error while fetching data") }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let decodedData = try decoder.decode(ResponseBody.self, from: data)
            
            DispatchQueue.main.async {
                self.videos = decodedData.videos.enumerated().map { index, video in
                    Video(id: video.id, pos: index, duration: video.duration, user: video.user, videoFiles: video.videoFiles)
                }
            }

        } catch {
            print("Error fetching data from Pexels: \(error)")
        }
    }
    
    

    // Method to get the next video
    func getNextVideo() -> Video? {
        print(currentIndex)
=======
import Foundation
import AVKit
import SwiftUI
import CachingPlayerItem

class VideoManager: ObservableObject {
    @Published private(set) var videos: [Video] = [] // Array to hold 3 videos
    @Published var currentIndex: Int = 0

    init() {
        Task.init {
            await findVideos()
        }
    }

    func setCurrInd(currind: Int) {
        currentIndex = currind
    }

    func getCurrInd() -> Int {
        return currentIndex
    }

    // Fetches a list of videos from the API for three different dates
    func findVideos() async {
        do {
            // Generate three different dates (e.g., 20241101_1.mp4, 20241102_2.mp4, 20241103_3.mp4)
            let videoNames = getThreeDates()

            // Loop through the video names and fetch the video URLs and durations
            var fetchedVideos: [Video] = []
            for (index, videoName) in videoNames.enumerated() {
                let videoURLString = "https://kcvbql2ezl.execute-api.ca-central-1.amazonaws.com/dev/videos?video_name=\(videoName)"
                
                guard let url = URL(string: videoURLString) else {
                    print("Invalid URL: \(videoURLString)")
                    continue
                }
                
                let (data, response) = try await URLSession.shared.data(from: url)
                guard (response as? HTTPURLResponse)?.statusCode == 200 else { continue }
                
                let decoder = JSONDecoder()
                let decodedData = try decoder.decode(ResponseBody.self, from: data)
                
                if let body = decodedData.body {
                    // Fetch the duration of the video dynamically using AVAsset
                    let videoDuration = await getVideoDuration(from: body)
                    
                    // Create a Video object for each fetched video
                    let video = Video(id: index, pos: index, duration: videoDuration, user: Video.User(id: 1, name: "User", url: ""),
                                      videoFiles: [Video.VideoFile(id: index, fileType: "mp4", link: body)])
                    fetchedVideos.append(video)
                }
            }
            
            DispatchQueue.main.async {
                // Update the videos array with the fetched video objects
                self.videos = fetchedVideos
            }
        } catch {
            print("Error fetching data: \(error)")
        }
    }

    // Helper function to generate the names of three dates (e.g., 20241101_1.mp4, 20241102_2.mp4, 20241103_3.mp4)
    func getThreeDates() -> [String] {
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"

        /** REPLACE WITH FORMATTED DATE WHEN READY FOR PRODUCTION */
        //let formattedDate = dateFormatter.string(from: currentDate)
        let formattedDate="20241102"
        var videoNames: [String] = []
        for i in 1..<4 {
            let videoName = "\(formattedDate)_\(i).mp4"
            videoNames.append(videoName)
        }
        
        return videoNames
    }

    // Get the next video (currently we are just handling the three videos in the array)
    func getNextVideo() -> Video? {
>>>>>>> Stashed changes
        guard !videos.isEmpty else { return nil }
        currentIndex = (currentIndex + 1) % videos.count // Wrap around if we reach the end
        let nextVideo = videos[currentIndex]
        return nextVideo
    }
<<<<<<< Updated upstream
}

// ResponseBody structure that follow the JSON data we get from the API
// Note: We're not adding all the variables returned from the API since not all of them are used in the app
struct ResponseBody: Decodable {
    var page: Int
    var perPage: Int
    var totalResults: Int
    var url: String
    var videos: [VideoResponse] // Changed to VideoResponse for API response mapping

}
struct VideoResponse: Decodable {
    var id: Int
    var duration: Int
    var user: Video.User
    var videoFiles: [Video.VideoFile]
=======
    
    // Fetch the video duration dynamically using AVAsset
    func getVideoDuration(from urlString: String) async -> Int {
        guard let url = URL(string: urlString) else { return 0 }
        
        // Load the AVAsset
        let asset = AVAsset(url: url)
        
        do {
            // Await asset loading and get the duration using the new API
                        //await asset.load(.duration)
            
            // Convert duration from CMTime to seconds (rounded to nearest second)
            let durationInSeconds = CMTimeGetSeconds(asset.duration)+2
            
            // Return the duration as an Int (in seconds)
            return Int(durationInSeconds)
        } catch {
            // Handle any errors in loading the AVAsset (e.g., network issues)
            print("Error loading video asset: \(error)")
            return 0 // Return 0 if there's an error
        }
    }
}

// Structure to decode the simplified JSON response
struct ResponseBody: Decodable {
    var statusCode: Int
    var body: String? // The video URL is directly in the "body"
>>>>>>> Stashed changes
}

struct Video: Identifiable, Decodable {
    var id: Int
    var pos: Int
    var progress: CGFloat = 0
<<<<<<< Updated upstream
    var duration: Int
=======
    var duration: Int // Duration of the video (seconds)
>>>>>>> Stashed changes
    var user: User
    var videoFiles: [VideoFile]
    
    struct User: Identifiable, Decodable {
        var id: Int
        var name: String
        var url: String
    }
    
    struct VideoFile: Identifiable, Decodable {
        var id: Int
<<<<<<< Updated upstream
        var quality: String
=======
>>>>>>> Stashed changes
        var fileType: String
        var link: String
    }
}
