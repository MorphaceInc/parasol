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
    // ObservableObject means that the views that use it will reload as it changes, Published also does this
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
    
    private var currentIndex: Int = 0
    
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
        guard !videos.isEmpty else { return nil }
        currentIndex = (currentIndex + 1) % videos.count // Wrap around if we reach the end
        let nextVideo = videos[currentIndex]
        return nextVideo
    }
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
}

struct Video: Identifiable, Decodable {
    var id: Int
    var pos: Int
    var progress: CGFloat = 0
    var duration: Int
    var user: User
    var videoFiles: [VideoFile]
    
    struct User: Identifiable, Decodable {
        var id: Int
        var name: String
        var url: String
    }
    
    struct VideoFile: Identifiable, Decodable {
        var id: Int
        var quality: String
        var fileType: String
        var link: String
    }
}
