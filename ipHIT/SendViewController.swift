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
    @IBOutlet weak var targetLabel: UILabel!
    
    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var sendingDataLabel: UILabel!
    let motionManager = CMMotionManager()
//    var recordStart = CFAbsoluteTimeGetCurrent()
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
        let vc = MCBrowserViewController(serviceType: serviceType, session: session)
        // 接続端末を１台に制限
        vc.maximumNumberOfPeers = 2
     }
    @IBAction func send2(_ sender: Any) {
    }
    
    @IBAction func send1(_ sender: Any) {
    }
    @IBAction func onExitButton(_ sender: Any) {
        if sessionState == 0{
        performSegue(withIdentifier: "fromSEND", sender: self)
        }
    }
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        motionManager.stopDeviceMotionUpdates()
        // たまに切れない時があるのでここで切断
        browser.stopBrowsingForPeers()
        advertiser.stopAdvertisingPeer()
        session.disconnect()
    }
   
  
 
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
     }
 
}

var sessionState:Int = 0
extension SendViewController: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        let message: String
         switch state {
        case .connected:
            sessionState=1
            message = "\(peerID.displayName) / connected."
        case .connecting:
             sessionState=1
            message = "\(peerID.displayName) / connecting."
        case .notConnected:
            sessionState=0
            message = "\(peerID.displayName) / notConnected."
        @unknown default:
             sessionState=0
            message = "\(peerID.displayName) / default."
        }
        DispatchQueue.main.async { [self] in
            didChangeLabel.text = message
            if sessionState==0{
                exitButton.alpha=1
            }else if sessionState==1{
                exitButton.alpha=0.3
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
//        guard let message = String(data: data, encoding: .utf8) else {
//            return
//        }
//        DispatchQueue.main.async {
//            print(message)
//        }
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

