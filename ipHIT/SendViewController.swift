//
//  P2ViewController.swift
//  ipHIT
//
//  Created by 黒田建彰 on 2022/02/15.
//

import UIKit
import MultipeerConnectivity
import CoreMotion
final class SendViewController: /*UITable*/UIViewController {
    @IBOutlet weak var didChangeLabel: UILabel!
    
    @IBOutlet weak var sendingDataLabel: UILabel!
    private var messages = [String]()
    let motionManager = CMMotionManager()
    var recordStart = CFAbsoluteTimeGetCurrent()
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
        recordStart = CFAbsoluteTimeGetCurrent()
        sendingDataLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 15, weight: .medium)
        setMotion()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        motionManager.stopDeviceMotionUpdates()
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
        //        drawBand(rectB: CGRect(x:x0,y:y0,width: ww,height: wh))
        drawBand(rectB: CGRect(x:xMid,y:y0,width: xd,height: 10))
        drawBand(rectB: CGRect(x:xMid,y:y0+15.0,width: yd,height: 10))
        drawBand(rectB: CGRect(x:xMid,y:y0+30.0,width: zd,height: 10))
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        ww=sendingDataLabel.frame.size.width// view.bounds.width
        wh=sendingDataLabel.frame.size.height// view.bounds.height
        x0=sendingDataLabel.frame.minX// .origin.x
        y0=sendingDataLabel.frame.minY// origin.y
        xMid=x0+ww/2
    }
     func setMotion(){
         guard motionManager.isDeviceMotionAvailable else { return }
         motionManager.deviceMotionUpdateInterval = 1 / 100//が最速の模様
   
         motionManager.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: { [self] (motion, error) in
             guard let motion = motion, error == nil else { return }
             let x=motion.rotationRate.x
             let y=motion.rotationRate.y
             let z=motion.rotationRate.z
             drawReceiveData(x: x, y: y, z: z)

             let time=CFAbsoluteTimeGetCurrent()-recordStart
             let str = String(format: "%04.3fsec:%.2f,%.2f,%.2f", time,x,y,z)
             do{
                 try session.send(str.data(using: .utf8)!,toPeers: session.connectedPeers,with: .reliable)
                 print(str)

             }catch let error{
                 print(error.localizedDescription)
             }
         })
     }
}

extension SendViewController: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        let message: String
        switch state {
        case .connected:
            message = "Send \(peerID.displayName) /connected."
        case .connecting:
            message = "Send \(peerID.displayName) /connecting."
        case .notConnected:
            message = "Send \(peerID.displayName) /notConnected."
        @unknown default:
            message = "Send \(peerID.displayName) /default."
        }
        DispatchQueue.main.async { [self] in
//            print(message)
            didChangeLabel.text = message
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let message = String(data: data, encoding: .utf8) else {
            return
        }
        DispatchQueue.main.async {
            print(message)
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

extension SendViewController: MCNearbyServiceAdvertiserDelegate {

    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }
}

extension SendViewController: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        guard let session = session else {
            return
        }
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 0)
    }
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
    }
}

