//  Bookkeeping for rendering the view of main page and for widget
//      1. UVChartFunctions: creating the UV plot based on forecast
//      2. UIDisplayFunctions: calculating values to display
//      3. SunscreenDepletionView: calculating the frames of sunscreen to display
//          a) struct SunscreenDepletionView for drain
//          b) struct AnimatedShakeView for wiggle

import Foundation
import SwiftUI
import SpriteKit
import ImageIO

//  MARK: 1. creating UV forecast plot
struct UVChartFunctions {
    //  plotting without sun indicator
    static func plotBasicChart(dataPoints: [(Date, Double)], smoothnessFactor: CGFloat) -> some View {
        GeometryReader { geometry in
            VStack {
                ZStack {
                    yAxisLabels(maxUV: dataPoints.map { $0.1 }.max() ?? 1, geometry: geometry)
                    curvePath(dataPoints: dataPoints, smoothnessFactor: smoothnessFactor, geometry: geometry)
                }
                xAxisLabels(dataPoints: dataPoints, geometry: geometry)
            }
        }
    }
    
    //  plotting with sun indicator
    static func plotEnhancedChart(dataPoints: [(Date, Double)], smoothnessFactor: CGFloat, currentDate: Date) -> some View {
        GeometryReader { geometry in
            ZStack {
                plotBasicChart(dataPoints: dataPoints, smoothnessFactor: smoothnessFactor)
                Image(systemName: "sun.max.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 30))
                    .shadow(color: .yellow.opacity(0.3), radius: 2, x: 0, y: 2)
                    .frame(width: 10, height: 10)
                    .position(positionForDate(currentDate, dataPoints: dataPoints, in: geometry))
            }
        }
    }
    
    //  smoothing the plot
    private static func curvePath(dataPoints: [(Date, Double)], smoothnessFactor: CGFloat, geometry: GeometryProxy) -> some View {
        let maxUV = dataPoints.map { $0.1 }.max() ?? 1
        
        return Path { path in
            let xScale = (geometry.size.width - 40) / CGFloat(dataPoints.count - 1)
            let yScale = (geometry.size.height - 40) / CGFloat(maxUV)
            
            guard dataPoints.count > 3 else { return }
            
            let points = dataPoints.enumerated().map { (index, point) in
                CGPoint(
                    x: CGFloat(index) * xScale + 40,
                    y: geometry.size.height - 40 - CGFloat(point.1) * yScale
                )
            }
            path.move(to: points[0])
            
            for i in 1..<points.count - 2 {
                let p0 = points[max(i - 1, 0)]
                let p1 = points[i]
                let p2 = points[i + 1]
                let p3 = points[min(i + 2, points.count - 1)]
                
                let catmullRomPoints = catmullRomSpline(p0: p0, p1: p1, p2: p2, p3: p3, smoothnessFactor: smoothnessFactor)
                
                for point in catmullRomPoints {
                    path.addLine(to: point)
                }
            }
            path.addLine(to: points[points.count - 1])
        }
        .stroke(Color.orange, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
        .shadow(color: Color.orange.opacity(0.3), radius: 4, x: 0, y: 2)
    }
    
    private static func catmullRomSpline(p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint, smoothnessFactor: CGFloat) -> [CGPoint] {
        let tension = 1 - smoothnessFactor // Invert smoothness factor for tension
        let numPoints = 20
        var points: [CGPoint] = []
        
        for i in 0..<numPoints {
            let t = CGFloat(i) / CGFloat(numPoints - 1)
            let t2 = t * t
            let t3 = t2 * t
            
            let m1 = (p2.x - p0.x) * tension
            let m2 = (p3.x - p1.x) * tension
            let x = (2 * p1.x - 2 * p2.x + m1 + m2) * t3 +
            (-3 * p1.x + 3 * p2.x - 2 * m1 - m2) * t2 +
            m1 * t + p1.x
            
            let n1 = (p2.y - p0.y) * tension
            let n2 = (p3.y - p1.y) * tension
            let y = (2 * p1.y - 2 * p2.y + n1 + n2) * t3 +
            (-3 * p1.y + 3 * p2.y - 2 * n1 - n2) * t2 +
            n1 * t + p1.y
            
            points.append(CGPoint(x: x, y: y))
        }
        return points
    }
    
    //  creating axes labels
    private static func yAxisLabels(maxUV: Double, geometry: GeometryProxy) -> some View {
        let stepCount = 5
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        
        return VStack(alignment: .trailing, spacing: 0) {
            ForEach(0...stepCount, id: \.self) { i in
                Spacer()
                if i < stepCount {
                    Text(formatter.string(from: NSNumber(value: maxUV * Double(stepCount - i) / Double(stepCount))) ?? "")
                        .font(.captionCustom)
                        .frame(width: 30, alignment: .trailing)
                }
            }
        }
        .frame(height: geometry.size.height - 40)
        .offset(y: -10)  // Adjust vertical alignment
    }
    
    private static func xAxisLabels(dataPoints: [(Date, Double)], geometry: GeometryProxy) -> some View {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "Ha"
        
        let markedHours = [9, 12, 15, 18]
        let calendar = Calendar.current
        
        func findNearestPoint(for hour: Int) -> CGFloat {
            let targetDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: dataPoints[0].0)!
            let index = dataPoints.indices.min(by: { abs(calendar.dateComponents([.minute], from: dataPoints[$0].0, to: targetDate).minute ?? 0) < abs(calendar.dateComponents([.minute], from: dataPoints[$1].0, to: targetDate).minute ?? 0) }) ?? 0
            let position = CGFloat(index) / CGFloat(dataPoints.count - 1)
            let result = position * geometry.size.width
            return position * geometry.size.width
        }
        
        let labelPositions = markedHours.map { findNearestPoint(for: $0) }
        
        return ZStack(alignment: .leading) {
            ForEach(Array(zip(markedHours, labelPositions)), id: \.0) { hour, position in
                Text(dateFormatter.string(from: calendar.date(bySettingHour: hour, minute: 0, second: 0, of: dataPoints[0].0)!).lowercased())
                    .font(.captionCustom)
                    .frame(width: 40)
                    .offset(x: position - 20)
            }
        }
        .frame(width: geometry.size.width, height: 20, alignment: .leading)
    }
    
    private static func positionForDate(_ date: Date, dataPoints: [(Date, Double)], in geometry: GeometryProxy) -> CGPoint {
        let maxUV = dataPoints.map { $0.1 }.max() ?? 1
        let xScale = (geometry.size.width - 40) / CGFloat(dataPoints.count - 1)
        let yScale = (geometry.size.height - 40) / maxUV
        
        let index = dataPoints.firstIndex { $0.0 > date } ?? dataPoints.count - 1
        let progress = CGFloat(date.timeIntervalSince(dataPoints[index - 1].0)) /
        CGFloat(dataPoints[index].0.timeIntervalSince(dataPoints[index - 1].0))
        
        let x = CGFloat(index - 1) * xScale + progress * xScale + 40
        let y1 = CGFloat(dataPoints[index - 1].1)
        let y2 = CGFloat(dataPoints[index].1)
        let y = geometry.size.height - 40 - (y1 + (y2 - y1) * progress) * yScale
        
        return CGPoint(x: x, y: y)
    }
}

//  MARK: 2. calculating understandable texts & time to display
struct UIDisplayFunctions {
    // convert SPF type to comprehensible statments
    func convertToSPFRecommendation() -> String {
        let value = SharedDataManager.shared.getEnvironmentData().spfRecm
        switch value {
        case 1:
            return "broad spectrum SPF 10"
        case 2:
            return "broad spectrum SPF 15"
        case 3:
            return "broad spectrum SPF 30"
        case 4:
            return "SPF 50 and SPF lip balm"
        case 5:
            return "SPF 50+ and SPF lip balm"
        case 6:
            return "Sun Protective Clothing, stay indoors"
        default:
            return "SPF 30 as precaution"
        }
    }
    
    // converting readable time from nextTime
    func displayNextTime() -> String {
        let envData = SharedDataManager.shared.getEnvironmentData()
        if Calendar.current.isDate(envData.nextTime, inSameDayAs: Date()) {
            if envData.nextTime < envData.sunsetTime {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .none
                dateFormatter.timeStyle = .short
                return dateFormatter.string(from: envData.nextTime)
            } else {
                return "good until sunset"
            }
        } else {
            //  MARK: ***need to implement re-fetch nextTime functions
            return "next time not at today"
        }
    }
}

//  MARK: 3. setting up view for sunscreen bottle
class DrainScene: SKScene {
    private var spriteNode: SKSpriteNode!
    private var textureAtlas: SKTextureAtlas!
    private(set) var textures: [SKTexture] = []
    var onSetupComplete: (() -> Void)?
    
    override func didMove(to view: SKView) {
        loadTextures()
        setupSprite()
        onSetupComplete?()
    }
    
    private func loadTextures() {
        textureAtlas = SKTextureAtlas(named: "DrainAtlas")
        textures = (0...299).compactMap { textureAtlas.textureNamed("Drain_\($0)") }
    }
    
    private func setupSprite() {
        spriteNode = SKSpriteNode(texture: textures.first)
        spriteNode.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(spriteNode)
    }
    
    func updateToFrame(_ frame: Int) {
        guard frame < textures.count else {
            print("out of bounds with frame \(frame) and texture number \(textures.count)")
            return
        }
        spriteNode.texture = textures[frame]
    }
}

//  MARK: 3.a) calculating frame of depleting sunscreen
struct SunscreenDepletionView: View {
    @State private var scene: DrainScene
    @State private var isSceneReady = false
    
    init() {
        let newScene = DrainScene(size: CGSize(width: 700, height: 700))
        newScene.scaleMode = .aspectFit
        _scene = State(initialValue: newScene)
    }
    
    var body: some View {
        SpriteView(scene: scene)
            .frame(width: 300, height: 300)
            .onAppear {
                if !isSceneReady {
                    scene.onSetupComplete = {
                        self.isSceneReady = true
                        self.updateFrame()
                    }
                } else {
                    updateFrame()
                }
            }
    }
    
    private func updateFrame() {
        let envData = SharedDataManager.shared.getEnvironmentData()
        let minToReapp = envData.minToReapp
        let nextTime = envData.nextTime
        
        let minLeft = max(0, Int(nextTime.timeIntervalSince(Date()) / 60))
        let calculatedFrame = min(Int(300.0 * Double(minToReapp - minLeft) / Double(minToReapp)), 299)
        scene.updateToFrame(calculatedFrame)
    }
}

//  MARK: 3.b) displaying wiggle of empty sunscreen
struct AnimatedShakeView: UIViewRepresentable {
    let gifName: String
    @Binding var isAnimating: Bool
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        view.addSubview(imageView)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalTo: view.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
        
        if let gifPath = Bundle.main.path(forResource: gifName, ofType: "gif"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: gifPath)),
           let imageSource = CGImageSourceCreateWithData(data as CFData, nil) {
            
            let frameCount = CGImageSourceGetCount(imageSource)
            var frames: [UIImage] = []
            var totalDuration: TimeInterval = 0
            
            for i in 0..<frameCount {
                if let cgImage = CGImageSourceCreateImageAtIndex(imageSource, i, nil) {
                    let uiImage = UIImage(cgImage: cgImage)
                    frames.append(uiImage)
                    
                    if let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, i, nil) as? [String: Any],
                       let gifProperties = properties[kCGImagePropertyGIFDictionary as String] as? [String: Any],
                       let duration = gifProperties[kCGImagePropertyGIFDelayTime as String] as? TimeInterval {
                        totalDuration += duration
                    }
                }
            }
            
            context.coordinator.frames = frames
            context.coordinator.totalDuration = totalDuration
            context.coordinator.imageView = imageView
            context.coordinator.startAnimating()
        }
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        if isAnimating {
            context.coordinator.startAnimating()
        } else {
            context.coordinator.stopAnimating()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(isAnimating: $isAnimating)
    }
    
    class Coordinator: NSObject {
        var frames: [UIImage] = []
        var totalDuration: TimeInterval = 0
        var imageView: UIImageView?
        @Binding var isAnimating: Bool
        var displayLink: CADisplayLink?
        
        init(isAnimating: Binding<Bool>) {
            self._isAnimating = isAnimating
        }
        
        func startAnimating() {
            guard displayLink == nil else { return }
            displayLink = CADisplayLink(target: self, selector: #selector(updateAnimation))
            displayLink?.add(to: .main, forMode: .common)
        }
        
        func stopAnimating() {
            displayLink?.invalidate()
            displayLink = nil
        }
        
        @objc func updateAnimation() {
            guard let imageView = imageView, !frames.isEmpty else { return }
            let frameDuration = totalDuration / TimeInterval(frames.count)
            let currentTime = CACurrentMediaTime()
            let index = Int((currentTime.truncatingRemainder(dividingBy: totalDuration)) / frameDuration)
            imageView.image = frames[index]
        }
    }
}
