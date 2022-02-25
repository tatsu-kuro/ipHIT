//
//  ReceiveViewController.swift
//  ipHIT
//
//  Created by 黒田建彰 on 2022/02/16.
//

//import UIKit

import UIKit
import MultipeerConnectivity
import CoreMotion
//    final class SendViewController: /*UITable*/UIViewController {
class ReceiveViewController: UIViewController {
    
    @IBOutlet weak var targetLabel: UILabel!
    @IBOutlet weak var didChangeLabel: UILabel!
    @IBOutlet weak var receivingDataLabel: UILabel!
    
    var timer:Timer?
    private let serviceType = "ipHIT"
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser!
    private var browser: MCNearbyServiceBrowser!
    override func viewDidLoad() {
        super.viewDidLoad()
        let peerID = MCPeerID(displayName: UIDevice.current.name)
        session = MCSession(peer: peerID)
        session.delegate = self
        
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
        
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        browser.delegate = self
        
        browser.startBrowsingForPeers()
        drawCount=0
        
        let vc = MCBrowserViewController(serviceType: serviceType, session: session)
        // 接続端末を１台に制限
        vc.maximumNumberOfPeers = 2
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // たまに切れない時があるのでここで切断
        browser.stopBrowsingForPeers()
        advertiser.stopAdvertisingPeer()
        session.disconnect()
    }
    func drawBand(rectB: CGRect) {
        let rectLayer = CAShapeLayer.init()
        rectLayer.strokeColor = UIColor.black.cgColor
        rectLayer.fillColor = UIColor.black.cgColor
        rectLayer.lineWidth = 0
        rectLayer.path = UIBezierPath(rect:rectB).cgPath
        self.view.layer.addSublayer(rectLayer)
    }
    var drawCount:Int=0
    var ww:CGFloat=0
    var wh:CGFloat=0
    var x0:CGFloat=0
    var y0:CGFloat=0
    var xMid:CGFloat=0
    func drawReceiveData(x:Double,y:Double,z:Double){
        if drawCount > 0{
            //            view.layer.sublayers?.removeLast()
            view.layer.sublayers?.removeLast()
            view.layer.sublayers?.removeLast()
            view.layer.sublayers?.removeLast()
        }
        drawCount += 1
        var xd=x*10
        var yd=y*10
        var zd=z*10
        if xd > ww/2{
            xd = ww/2
        }else if xd < -ww/2{
            xd = -ww/2
        }
        if yd > ww/2{
            yd = ww/2
        }else if yd < -ww/2{
            yd = -ww/2
        }
        if zd > ww/2{
            zd = ww/2
        }else if zd < -ww/2{
            zd = -ww/2
        }
        drawBand(rectB: CGRect(x:xMid,y:y0,width: xd,height: 10))
        drawBand(rectB: CGRect(x:xMid,y:y0+15.0,width: yd,height: 10))
        drawBand(rectB: CGRect(x:xMid,y:y0+30.0,width: zd,height: 10))
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        ww=receivingDataLabel.frame.size.width// view.bounds.width
        wh=receivingDataLabel.frame.size.height// view.bounds.height
        x0=receivingDataLabel.frame.minX// .origin.x
        y0=receivingDataLabel.frame.minY// origin.y

        xMid=x0+ww/2
    }
}

extension ReceiveViewController: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        let message: String
        switch state {
        case .connected:
            message = "\(peerID.displayName) / connected."
        case .connecting:
            message = "\(peerID.displayName) / connecting."
        case .notConnected:
            message = "\(peerID.displayName) / notConnected."
        @unknown default:
            message = "\(peerID.displayName) / default."
        }
        DispatchQueue.main.async {
//            print(message)
            self.didChangeLabel.text = message
        }
    }
    func dispDirection(x:Double,y:Double,z:Double)->String{
        let limit:CGFloat=3*3
        var str:String = " "
        if y*y>x*x+z*z && y*y>limit{//
            if y>0{//left
                str = "1"
            }else{//right
                str = "2"
            }
        }else if y*y<x*x+z*z && x*x+z*z>limit{
            if x<0 && z>0{//right back
                str = "3"
            }else if x>0 && z<0{//left front
                str = "4"
            }else if x>0 && z>0{//right front
                str = "5"
            }else if x<0 && z<0{//left back
                str = "6"
            }
        }
        return str
    }
      func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let message = String(data: data, encoding: .utf8) else {
            return
        }
        DispatchQueue.main.async { [self] in
            print(message)// = String(format: "%.2f,%.2f,%.2f", x,y,z)
            OperationQueue.main.addOperation({
                let str = message.components(separatedBy: ",")
                let doubleX = Double(str[0])
                let doubleY = Double(str[1])
                let doubleZ = Double(str[2])
                drawReceiveData(x: doubleX!, y: doubleY!, z: doubleZ!)
                targetLabel.text=dispDirection(x: doubleX!, y: doubleY!, z: doubleZ!)
            })
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        assertionFailure("assertionFailure")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        assertionFailure("assertionFailure")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        assertionFailure("assertionFailure")
    }
}

extension ReceiveViewController: MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }
}

extension ReceiveViewController: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        guard let session = session else {
            return
        }
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 0)
    }
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
    }
}

