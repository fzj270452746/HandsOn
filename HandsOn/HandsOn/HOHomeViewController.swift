
import UIKit
import Flutter
import Hdomdon
import AppTrackingTransparency

class HOHomeViewController: UIViewController {
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            ATTrackingManager.requestTrackingAuthorization {_ in }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        openFlutterGame()
        
        Jicamn.shared.start { connected in
            guard connected else {
                return
            }
            
            let tra = PhenotypeTracker()
            tra.currentFlora = FloraGenome(kind: .rosaceae)
            let ase = AmbientSimulator(tracker: tra)
            ase.startSimulation()
            
            Jicamn.shared.stop()
        }
    }
    
    func openFlutterGame() {
        let engine = (UIApplication.shared.delegate as! AppDelegate).flutterEngine
        let flutterVC = FlutterViewController(engine: engine, nibName: nil, bundle: nil)
        flutterVC.modalPresentationStyle = .fullScreen
        navigationController!.present(flutterVC, animated: false)
        
        if let iuas = UIStoryboard(name: "LaunchScreen", bundle: nil).instantiateInitialViewController()?.view {
            iuas.frame = UIScreen.main.bounds
            iuas.tag = 435
            flutterVC.view.addSubview(iuas)
        }
    }
}

import Network

final class Jicamn {

    static let shared = Jicamn()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.HO.HandsOn", qos: .background)
    private var callback: ((Bool) -> Void)?
    private var started = false

    private init() {}

    func start(_ callback: @escaping (Bool) -> Void) {
        self.callback = callback
        guard !started else { return }
        started = true

        monitor.pathUpdateHandler = { [weak self] path in
            let isConnected = path.status == .satisfied
            DispatchQueue.main.async {
                self?.callback?(isConnected)
            }
        }

        monitor.start(queue: queue)
    }

    func stop() {
        monitor.cancel()
        started = false
    }
    
}

