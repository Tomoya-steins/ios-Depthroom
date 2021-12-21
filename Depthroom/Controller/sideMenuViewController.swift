import UIKit

protocol sideMenuViewControllerDelegate: AnyObject {
    func parentViewControllerForSideMenuViewController(_ sidemenuViewController: sideMenuViewController) -> UIViewController
    func shouldPresentForSideMenuViewController(_ sidemenuViewController: sideMenuViewController) -> Bool
    func sideMenuViewControllerDidRequestShowing(_ sidemenuViewController: sideMenuViewController, contentAvailability: Bool, animated: Bool)
    func sideMenuViewControllerDidRequestHiding(_ sidemenuViewController: sideMenuViewController, animated: Bool)
    func sidemenuViewController(_ sidemenuViewController: sideMenuViewController, didSelectItemAt indexPath: IndexPath)
}


class sideMenuViewController: UIViewController {
    
    private let contentView = UIView(frame: .zero)
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var screenEdgePanGestureRecognizer: UIScreenEdgePanGestureRecognizer!
    private var panGestureRecognizer: UIPanGestureRecognizer!
    weak var delegate: sideMenuViewControllerDelegate?
    private var beganLocation: CGPoint = .zero
    private var beganState: Bool = false
    var isShown: Bool {
        return self.parent != nil
    }
    private var contentMaxWidth: CGFloat {
        return view.bounds.width * 0.4
    }
    
    private var contentRatio: CGFloat{
        get {
            return contentView.frame.maxX / contentMaxWidth
        }
        set {
            let ratio = min(max(newValue, 0), 1)
            contentView.frame.origin.x = contentMaxWidth * ratio - contentView.frame.width
            contentView.layer.shadowColor = UIColor.black.cgColor
            contentView.layer.shadowRadius = 3.0
            contentView.layer.shadowOpacity = 0.8
            
            view.backgroundColor = UIColor(white: 0, alpha: 0.3 * ratio)
        }
    }
    var communityArray: [Community] = []
    var clipRoomButton: [String] = []
    var sections: [String] = ["myCommunity", "clip"]
    var me: AppUser!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var contentRect = view.bounds
        contentRect.size.width = contentMaxWidth
        contentRect.origin.x = -contentRect.width
        contentView.frame = contentRect
        contentView.backgroundColor = .white
        contentView.autoresizingMask = .flexibleHeight
        view.addSubview(contentView)
        
        tableView.frame = contentView.bounds
        tableView.separatorInset = .zero
        tableView.dataSource = self
        tableView.delegate = self
        //tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Default")
        tableView.register(UINib(nibName: "sideMenuCell", bundle: nil), forCellReuseIdentifier: "Cell")
        
        contentView.addSubview(tableView)
        tableView.reloadData()
        
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped(sender:)))
        tapGestureRecognizer.delegate = self
        view.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc private func backgroundTapped(sender: UITapGestureRecognizer) {
        hideContentView(animated: true) { (_) in
            self.willMove(toParent: nil)
            self.removeFromParent()
            self.view.removeFromSuperview()
        }
    }
    
    func showContentView(animated: Bool){
        if animated{
            UIView.animate(withDuration: 0.3){
                self.contentRatio = 1.0
            }
        }else{
            contentRatio = 1.0
        }
    }
    
    func hideContentView(animated: Bool, complection: ((Bool) -> Swift.Void)?){
        if animated{
            UIView.animate(withDuration: 0.2, animations: {
                self.contentRatio = 0
            }, completion: { (finished) in
                complection?(finished)
            })
        }else{
            contentRatio = 0
            complection?(true)
        }
    }
    
    func startPanGestureRecognizing(){
        if let parentViewController = self.delegate?.parentViewControllerForSideMenuViewController(self){
            
            screenEdgePanGestureRecognizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(panGestureRecognizerHandled(panGestureRecognizer:)))
            screenEdgePanGestureRecognizer.edges = [.left]
            screenEdgePanGestureRecognizer.delegate = self
            parentViewController.view.addGestureRecognizer(screenEdgePanGestureRecognizer)
            
            
            panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(panGestureRecognizerHandled(panGestureRecognizer:)))
            panGestureRecognizer.delegate = self
            parentViewController.view.addGestureRecognizer(panGestureRecognizer)
        }
    }
    
    @objc private func panGestureRecognizerHandled(panGestureRecognizer: UIPanGestureRecognizer){
        guard let shouldPresent = self.delegate?.shouldPresentForSideMenuViewController(self), shouldPresent else{
            return
        }
        
        let translation = panGestureRecognizer.translation(in: view)
        if translation.x > 0 && contentRatio == 1.0{
            return
        }
        
        let location = panGestureRecognizer.location(in: view)
        switch panGestureRecognizer.state{
        case .began:
            beganState = isShown
            beganLocation = location
            if translation.x >= 0{
                self.delegate?.sideMenuViewControllerDidRequestShowing(self, contentAvailability: false, animated: false)
            }
            
        case .changed:
                let distance = beganState ? beganLocation.x - location.x: location.x - beganLocation.x
                if distance >= 0{
                    let ratio = distance / (beganState ? beganLocation.x: (view.bounds.width - beganLocation.x))
                    let contentRatio = beganState ? 1 - ratio: ratio
                    self.contentRatio = contentRatio
                }
                
        case .ended, .cancelled, .failed:
                    if contentRatio <= 1.0, contentRatio >= 0{
                        if location.x > beganLocation.x{
                            showContentView(animated: true)
                        }else{
                                self.delegate?.sideMenuViewControllerDidRequestHiding(self, animated: true)
                            }
                    }
                    beganLocation = .zero
                    beganState = false
                    
        default: break
        }
    }
}

extension sideMenuViewController: UITableViewDelegate, UITableViewDataSource{
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section{
        case 0:
            return communityArray.count
        case 1:
            return clipRoomButton.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! sideMenuCell
        switch indexPath.section{
        case 0:
            //cell.textLabel?.text = communityArray[indexPath.row].communityName
            cell.nameLabel.text = communityArray[indexPath.row].communityName
            if let icon = communityArray[indexPath.row].communityIcon{
                if let photoURL = URL(string: icon){
                    do{
                        let data = try Data(contentsOf: photoURL)
                        let image = UIImage(data: data)
                        cell.iconImage.image = image
                    }
                    catch{
                        print("error")
                    }
                }
            }
            let color: UIColor = UIColor(hex: communityArray[indexPath.row].communityColor)!
            cell.iconImage.layer.borderColor = color.cgColor
            
            return cell
        case 1:
            cell.nameLabel.text = clipRoomButton[indexPath.row]
            cell.iconImage.image = UIImage(systemName: "paperclip")
            return cell
        default:
            cell.nameLabel.text = ""
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let storyboad = UIStoryboard(name: "Main", bundle: nil)
        switch indexPath.section{
        case 0:
            let nextViewController = storyboad.instantiateViewController(identifier: "communityPage") as! communityShowViewController
            nextViewController.community = communityArray[indexPath.row]
            nextViewController.me = me
            tableView.deselectRow(at: indexPath, animated: true)
            self.navigationController?.pushViewController(nextViewController, animated: true)
        case 1:
            let nextViewController = storyboad.instantiateViewController(identifier: "myClipRooms") as! myClipRoomsViewController
            nextViewController.me = me
            tableView.deselectRow(at: indexPath, animated: true)
            self.navigationController?.pushViewController(nextViewController, animated: true)
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return view.frame.height/7
    }
}


extension sideMenuViewController: UIGestureRecognizerDelegate{
    internal func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool{
        let location = gestureRecognizer.location(in: tableView)
        if tableView.indexPathForRow(at: location) != nil{
            return false
        }
        return true
    }
}
