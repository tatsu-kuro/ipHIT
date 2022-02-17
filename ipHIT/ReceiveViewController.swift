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
    
    @IBOutlet weak var didChangeLabel: UILabel!
    @IBOutlet weak var receivingDataLabel: UILabel!
    private var messages = [String]()
//    let motionManager = CMMotionManager()
//    var recordStart:Double=0// = CFAbsoluteTimeGetCurrent()
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
        receivingDataLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 15, weight: .medium)

        browser.startBrowsingForPeers()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        // たまに切れない時があるのでここで切断
        browser.stopBrowsingForPeers()
        advertiser.stopAdvertisingPeer()
        session.disconnect()
    }
    
//    func setMotion(){
//        guard motionManager.isDeviceMotionAvailable else { return }
//        motionManager.deviceMotionUpdateInterval = 1 / 100//が最速の模様
//
//        motionManager.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: { [self] (motion, error) in
//            guard let motion = motion, error == nil else { return }
//            let str = String(format:"%.2f,%.2f,%.2f",motion.rotationRate.x,motion.rotationRate.y,motion.rotationRate.z)
//            do{
//                try session.send(str.data(using: .utf8)!,toPeers: session.connectedPeers,with: .reliable)
//                print(str)
//            }catch let error{
//                print(error.localizedDescription)
//            }
//            //             if self.recordStart == 0{
//            //                 self.gyro.append(0)//CFAbsoluteTimeGetCurrent())
//            //             }else{
//            //                 self.gyro.append(CFAbsoluteTimeGetCurrent()-self.recordStart)
//            //             }
//            //             self.gyro.append(motion.rotationRate.y)//holizontal
//            //             self.gyro.append(-motion.rotationRate.x*1.414)//verticalは４５度ズレているので、√２
//        })
//    }
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

extension ReceiveViewController: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        let message: String
        switch state {
        case .connected:
            message = "Receive \(peerID.displayName) /connected."
        case .connecting:
            message = "Receive \(peerID.displayName) /connecting."
        case .notConnected:
            message = "Receive \(peerID.displayName) /notConnected."
        @unknown default:
            message = "Receive \(peerID.displayName) /default."
        }
        DispatchQueue.main.async {
//            print(message)
            self.didChangeLabel.text = message
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let message = String(data: data, encoding: .utf8) else {
            return
        }
        DispatchQueue.main.async { [self] in
            print(message)
            OperationQueue.main.addOperation({
                // UI の更新処理を記述する
                print(message)
                receivingDataLabel.text = message
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

