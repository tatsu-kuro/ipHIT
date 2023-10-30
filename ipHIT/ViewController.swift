//
//  ViewController.swift
//  ipHIT
//
//  Created by 黒田建彰 on 2022/02/15.
//

import UIKit
import MultipeerConnectivity

class ViewController: /*UITable*/UIViewController {
    
    @IBOutlet weak var receiveLabel: UILabel!
    private let serviceType = "ipHIT"
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser!
    private var browser: MCNearbyServiceBrowser!
    override func viewDidLoad() {
        super.viewDidLoad()
        startPeer()
    }
 
    func startPeer(){
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
    
    func stopPeer(){    // 切断
        browser.stopBrowsingForPeers()
        advertiser.stopAdvertisingPeer()
        session.disconnect()
    }
    
    @IBAction func send2(_ sender: Any) {
        let str = "send2"
        do{
            try session.send(str.data(using: .utf8)!,toPeers: session.connectedPeers,with: .reliable)
            print(str)
            
        }catch let error{
            print(error.localizedDescription)
        }
    }
    
    @IBAction func send1(_ sender: Any) {
        let str = "send1"
        do{
            try session.send(str.data(using: .utf8)!,toPeers: session.connectedPeers,with: .reliable)
            print(str)
            //     print(String(format: "send:%",str))
        }catch let error{
            print(error.localizedDescription)
        }
    }
}

extension ViewController: MCSessionDelegate {
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
         DispatchQueue.main.async { [self] in
               receiveLabel.text = message
         }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let message = String(data: data, encoding: .utf8) else {
            return
        }
        DispatchQueue.main.async {
            self.receiveLabel.text=message
            // .settitle(print(String(format: "command:%s", message))
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

extension ViewController: MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }
}

extension ViewController: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        guard let session = session else {
            return
        }
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 0)
    }
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
    }
}

