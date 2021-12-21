import UIKit
 
class DrawView: UIView {
 
    override init(frame: CGRect) {
        super.init(frame: frame);
        self.backgroundColor = UIColor.clear;
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        
        let rectangle = UIBezierPath(rect: CGRect(x: frame.width/16, y: 4*frame.height/7, width: frame.width/4, height: frame.width/4))
        // 内側の色
        UIColor(red: 1, green: 0.5, blue: 0, alpha: 0.3).setFill()
        // 内側を塗りつぶす
        rectangle.fill()
        // 線の色
        UIColor(red: 1, green: 0.5, blue: 0, alpha: 1.0).setStroke()
        // 線の太さ
        rectangle.lineWidth = 2.0
        // 線を塗りつぶす
        rectangle.stroke()
        
    }
 
}
