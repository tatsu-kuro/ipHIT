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

     func setMotion(){
         guard motionManager.isDeviceMotionAvailable else { return }
         motionManager.deviceMotionUpdateInterval = 1 / 100//が最速の模様
   
         motionManager.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: { [self] (motion, error) in
             guard let motion = motion, error == nil else { return }

//             var xf="-"
//             var yf="-"
//             var zf="-"
             var x=motion.rotationRate.x
             var y=motion.rotationRate.y
             var z=motion.rotationRate.z

//             if motion.rotationRate.x >= 0{
//                 xf="  "
//             }
//             if motion.rotationRate.y >= 0{
//                 yf="  "
//             }
//             if motion.rotationRate.z >= 0{
//                 zf="  "
//             }
//             x=abs(x)
//             y=abs(y)
//             z=abs(z)
             let time=CFAbsoluteTimeGetCurrent()-recordStart
             let str = String(format: "%04.3fsec:%.2f,%.2f,%.2f", time,x,y,z)

//             let str = String(format: "%04.3fsec:%@%.2f,%@%.2f,%@%.2f", time,xf,x,yf,y,zf,z)
//             let str = String(format: "%.2fs:%.2f,%.2f,%.2f",time,motion.rotationRate.x,motion.rotationRate.y,motion.rotationRate.z)
//             sendingDataLabel.text = str
             
//             let str = String(format:"%04d-%.2f: %.2f,%.2f,%.2f",count,CFAbsoluteTimeGetCurrent()-recordStart,motion.rotationRate.x,motion.rotationRate.y,motion.rotationRate.z)
             do{
                 try session.send(str.data(using: .utf8)!,toPeers: session.connectedPeers,with: .reliable)
                 print(str)
                 sendingDataLabel.text = str

             }catch let error{
                 print(error.localizedDescription)
             }
//             if self.recordStart == 0{
//                 self.gyro.append(0)//CFAbsoluteTimeGetCurrent())
//             }else{
//                 self.gyro.append(CFAbsoluteTimeGetCurrent()-self.recordStart)
//             }
//             self.gyro.append(motion.rotationRate.y)//holizontal
//             self.gyro.append(-motion.rotationRate.x*1.414)//verticalは４５度ズレているので、√２
         })
     }
//    self.gyro.append(CFAbsoluteTimeGetCurrent()-self.recStart)

//    motionManager.stopDeviceMotionUpdates()//ここで止めたが良さそう。

 //    return String(format: "%.2f,%.2f,%.2f",x,y,z)
//    @objc private func sendMessage(_ sender: Any) {
//        let message = "\(session.myPeerID.displayName)からのメッセージ"
//        do {
//            try session.send(message.data(using: .utf8)!, toPeers: session.connectedPeers, with: .reliable)
//            print(message)
//        } catch let error {
//            print(error.localizedDescription)
//        }
//    }
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

