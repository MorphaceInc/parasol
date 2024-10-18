//

import SwiftUI

struct ProgressBarView: View {
    @Binding var value : Int
    @Binding var video : Video
    var body: some View {
        VStack(alignment: .trailing, spacing: 10){
            //Text("Progress \(percentage(value: value))")
            ZStack(alignment: .leading){
        Capsule().frame(width: UIScreen.main.bounds.width-20).foregroundColor(Color.gray)
        
                Capsule().frame(width: (UIScreen.main.bounds.width-20)*CGFloat(value)/CGFloat(video.duration)).foregroundColor(Color.black).animation(.linear)
            }.frame( height: 3)        }
    }
    func percentage(value : Int)->String{
        let value = Double(value)
        let v = (100.0/Double(video.duration))*value
        let intValue = Int(ceil(v))
        return "\(intValue) %"
        
    }
}

/*struct ProgressBarView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressBarView(value: .constant(2))
    }
}*/
