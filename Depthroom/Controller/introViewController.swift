//
//  introViewController.swift
//  Depthroom
//
//  Created by NakagawaTomoya on 2021/12/16.
//

import UIKit
import Lottie

class introViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var firstView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!{
        didSet{
            scrollView.delegate = self
            scrollView.isPagingEnabled = true
            scrollView.showsHorizontalScrollIndicator = false
        }
    }
    @IBOutlet weak var pageControl: UIPageControl!{
        didSet{
            pageControl.isUserInteractionEnabled = false
            UIPageControl.appearance().pageIndicatorTintColor = .lightGray
            UIPageControl.appearance().currentPageIndicatorTintColor = .green
            pageControl.numberOfPages = 4
        }
    }
    //2つ目のview「気になるコミュニティを」「選んで参加してみよう」
    //「選んで参加してみよう」はいらないかも
    @IBOutlet weak var secondViewLabel1: UILabel!
    @IBOutlet weak var secondViewLabel2: UILabel!
    @IBOutlet weak var lastViewLabel: UILabel!
    @IBOutlet weak var lastViewButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        firstViewshowAnimation()
        firstViewLabelSet()
        secondViewLabelSet()
        lastViewLabelSet()
        lastViewButtonSet()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        pageControl.currentPage = Int(scrollView.contentOffset.x/scrollView.frame.width)
    }
    
    func firstViewshowAnimation(){
        //チャットアニメーション
        let animationChatView = AnimationView(name: "chat")
        animationChatView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 1*view.frame.height/2)
        //animationView.center = self.view.center
        animationChatView.loopMode = .loop
        animationChatView.contentMode = .scaleAspectFit
        animationChatView.animationSpeed = 1
        firstView.addSubview(animationChatView)
        //グッドアニメーション?
        let animationGoodView = AnimationView(name: "cats")
        animationGoodView.frame = CGRect(x: 0, y: view.center.y , width: view.frame.width/2, height: view.frame.height/2)
        animationGoodView.loopMode = .loop
        animationGoodView.contentMode = .scaleAspectFit
        animationGoodView.animationSpeed = 1
        firstView.addSubview(animationGoodView)
        
        animationGoodView.play()
        animationChatView.play()
    }
    func firstViewLabelSet(){
        let arayuruLabel = UILabel(frame: CGRect(x: 5, y: view.center.y, width: 4*view.frame.width/5, height: view.frame.height/12))
        let minnatoLabel = UILabel(frame: CGRect(x: 0, y: view.center.y + view.frame.height/9, width: view.frame.width, height: view.frame.height/12))
        
        //あらゆる話題を
        arayuruLabel.textAlignment = NSTextAlignment.left
        arayuruLabel.font = UIFont(name: "Courier-Bold", size: 30)
        arayuruLabel.adjustsFontSizeToFitWidth = true
        arayuruLabel.text = "あらゆる話題を"
        //「話題」だけ色変える
        let arayuruLabelCustom = NSMutableAttributedString(string: arayuruLabel.text!)
        //まずは「話」
        arayuruLabelCustom.addAttributes([
            .foregroundColor: UIColor(hex: "#EF7779")!,
        ], range: NSMakeRange(4, 1))
        //次に「題」
        arayuruLabelCustom.addAttributes([
            .foregroundColor: UIColor(hex: "#FADA55")!,
        ], range: NSMakeRange(5, 1))
        arayuruLabel.attributedText = arayuruLabelCustom
        firstView.addSubview(arayuruLabel)
        
        //みんなと共有
        minnatoLabel.textAlignment = NSTextAlignment.right
        minnatoLabel.font = UIFont(name: "Courier-Bold", size: 30)
        minnatoLabel.adjustsFontSizeToFitWidth = true
        minnatoLabel.text = "みんなと共有！"
        //「共有!」だけ色変える
        let minnatoLabelCustom = NSMutableAttributedString(string: minnatoLabel.text!)
        //まずは「共」
        minnatoLabelCustom.addAttributes([
            .foregroundColor: UIColor(hex: "#F7A654")!,
        ], range: NSMakeRange(4, 1))
        //次に「有」
        minnatoLabelCustom.addAttributes([
            .foregroundColor: UIColor(hex: "#99FF94")!,
        ], range: NSMakeRange(5, 1))
        //最後に「！」
        minnatoLabelCustom.addAttributes([
            .foregroundColor: UIColor(hex: "#B9EAED")!,
        ], range: NSMakeRange(6, 1))
        minnatoLabel.attributedText = minnatoLabelCustom
        firstView.addSubview(minnatoLabel)
    }
    
    func secondViewLabelSet(){
        let label1Custom = NSMutableAttributedString(string: secondViewLabel1.text!)
        //「コミュニティ」だけ色変える
        //「コ」
        label1Custom.addAttributes([
            .foregroundColor: UIColor(hex: "#EF7779")!,
        ], range: NSMakeRange(4, 1))
        //「ミ」
        label1Custom.addAttributes([
            .foregroundColor: UIColor(hex: "#FADA55")!,
        ], range: NSMakeRange(5, 1))
        //「ュ」
        label1Custom.addAttributes([
            .foregroundColor: UIColor(hex: "#F7A654")!,
        ], range: NSMakeRange(6, 1))
        //「ニ」
        label1Custom.addAttributes([
            .foregroundColor: UIColor(hex: "#B9EAED")!,
        ], range: NSMakeRange(7, 1))
        //「テ」
        label1Custom.addAttributes([
            .foregroundColor: UIColor(hex: "#99FF94")!,
        ], range: NSMakeRange(8, 1))
        //「ィ」
        label1Custom.addAttributes([
            .foregroundColor: UIColor(hex: "#D0C4FC")!,
        ], range: NSMakeRange(9, 1))
        secondViewLabel1.attributedText = label1Custom
    }
    
    func lastViewLabelSet(){
        let labelCustom = NSMutableAttributedString(string: lastViewLabel.text!)
        //「T」
        labelCustom.addAttributes([
            .foregroundColor: UIColor(hex: "#EF7779")!,
        ], range: NSMakeRange(0, 1))
        //「C」
        labelCustom.addAttributes([
            .foregroundColor: UIColor(hex: "#F7A654")!,
        ], range: NSMakeRange(2, 1))
        lastViewLabel.attributedText = labelCustom
    }
    func lastViewButtonSet(){
        lastViewButton.setTitleColor(.white, for: .normal)
        lastViewButton.layer.cornerRadius = 10
        let color: UIColor = UIColor(hex: "#FF6A6A")!
        lastViewButton.backgroundColor = color
    }
    
    @IBAction func lastViewButtonTapped(_ sender: Any) {
        let nextViewController = self.storyboard?.instantiateViewController(identifier: "newRegister") as! newRegisterViewController
        self.navigationController?.pushViewController(nextViewController, animated: true)
    }
}
