import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {

    // Handle deep-links from Live Activity buttons (pomodorotimer://toggle, pomodorotimer://skip)
    override func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        super.scene(scene, openURLContexts: URLContexts)

        guard let url = URLContexts.first?.url,
              url.scheme == "pomodorotimer" else { return }

        let action = url.host ?? ""
        TimerLiveActivityManager.handleURLAction(action)
    }
}
