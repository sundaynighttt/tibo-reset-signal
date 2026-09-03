import AppKit
import Combine
import OSLog

@main
@MainActor
final class TiboResetSignalApp: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private static var retainedDelegate: TiboResetSignalApp?

    private let store = SignalStore()
    private let statusMenu = NSMenu()
    private let logger = Logger(subsystem: "com.sundaynighttt.tibo-reset-signal", category: "MenuBar")
    private var statusItem: NSStatusItem?
    private var storeCancellable: AnyCancellable?
    private var loginItemError: String?

    static func main() {
        let delegate = TiboResetSignalApp()
        retainedDelegate = delegate
        let application = NSApplication.shared
        application.delegate = delegate
        application.setActivationPolicy(.accessory)
        application.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusMenu.delegate = self
        installStatusItem()
        observeChanges()
        observeSystemEvents()
    }

    func applicationWillTerminate(_ notification: Notification) {
        storeCancellable = nil
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        ensureStatusItemVisible()
        DispatchQueue.main.async { [weak self] in self?.statusItem?.button?.performClick(nil) }
        return false
    }

    func menuWillOpen(_ menu: NSMenu) {
        rebuildMenu()
    }

    private func installStatusItem() {
        if let statusItem { NSStatusBar.system.removeStatusItem(statusItem) }
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.menu = statusMenu
        item.isVisible = true
        statusItem = item
        updateStatusTitle()
        rebuildMenu()
    }

    private func observeChanges() {
        storeCancellable = store.objectWillChange.sink { [weak self] in
            DispatchQueue.main.async {
                self?.updateStatusTitle()
            }
        }
    }

    private func observeSystemEvents() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(restoreStatusItem),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(restoreStatusItem),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    @objc private func restoreStatusItem(_ notification: Notification) {
        ensureStatusItemVisible()
    }

    private func ensureStatusItemVisible() {
        guard let statusItem, statusItem.button != nil else {
            installStatusItem()
            return
        }
        statusItem.isVisible = true
        statusItem.menu = statusMenu
        updateStatusTitle()
        logger.info("Status item restored")
    }

    private func updateStatusTitle() {
        guard let button = statusItem?.button else { return }
        let title = SignalFormatter.menuTitle(payload: store.payload, now: store.now)
        button.title = title
        button.font = NSFont.monospacedDigitSystemFont(ofSize: NSFont.systemFontSize, weight: .medium)
        button.toolTip = "Tibo 리셋 신호"
        button.setAccessibilityLabel("Tibo 리셋 신호 \(title)")
        button.setAccessibilityIdentifier("TiboResetSignalStatusItem")
    }

    private func rebuildMenu() {
        statusMenu.removeAllItems()
        let level = store.payload?.effectiveLevel(now: store.now) ?? .stale

        addHeader("\(level.emoji) \(level.localizedName)")
        if let payload = store.payload {
            addInfo("점수 \(payload.signal.score) / 10")
            addInfo(SignalFormatter.relativeUpdate(payload.source.lastSuccessfulCheckAt, now: store.now))
        } else {
            addInfo("공개 신호 확인 중…")
        }
        if let errorMessage = store.errorMessage { addInfo(errorMessage) }
        if let loginItemError { addInfo(loginItemError) }

        statusMenu.addItem(.separator())
        addHeader("유력 근거")
        if let evidence = store.payload?.evidence, !evidence.isEmpty {
            for item in evidence {
                let reasons = item.reasonCodes.prefix(2).map(SignalFormatter.reason).joined(separator: " · ")
                let menuItem = actionItem(
                    title: "\(item.score)점 · \(reasons)",
                    action: #selector(openEvidence(_:))
                )
                menuItem.representedObject = item.url
                statusMenu.addItem(menuItem)
            }
        } else {
            addInfo("활성 근거 없음")
        }

        statusMenu.addItem(.separator())
        let refresh = actionItem(
            title: store.isRefreshing ? "새로고침 중…" : "지금 새로고침",
            action: #selector(refreshSignal)
        )
        refresh.isEnabled = !store.isRefreshing
        statusMenu.addItem(refresh)

        let loginItem = actionItem(title: "로그인 시 자동 실행", action: #selector(toggleLaunchAtLogin))
        loginItem.state = LoginItemManager.isEnabled ? .on : .off
        statusMenu.addItem(loginItem)
        statusMenu.addItem(actionItem(title: "@thsottiaux 프로필 열기", action: #selector(openProfile)))
        statusMenu.addItem(actionItem(title: "데이터 상태 열기", action: #selector(openDataStatus)))
        statusMenu.addItem(.separator())
        statusMenu.addItem(actionItem(title: "종료", action: #selector(quitApplication)))
    }

    private func addHeader(_ title: String) {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        item.attributedTitle = NSAttributedString(
            string: title,
            attributes: [.font: NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)]
        )
        statusMenu.addItem(item)
    }

    private func addInfo(_ title: String) {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        statusMenu.addItem(item)
    }

    private func actionItem(title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    @objc private func refreshSignal() { store.refresh() }

    @objc private func openEvidence(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        NSWorkspace.shared.open(url)
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            try LoginItemManager.setEnabled(!LoginItemManager.isEnabled)
            loginItemError = nil
        } catch {
            loginItemError = "자동 실행 설정 실패: \(error.localizedDescription)"
        }
        rebuildMenu()
    }

    @objc private func openProfile() {
        NSWorkspace.shared.open(URL(string: "https://x.com/thsottiaux")!)
    }

    @objc private func openDataStatus() {
        NSWorkspace.shared.open(SignalClient.productionURL)
    }

    @objc private func quitApplication() {
        NSApplication.shared.terminate(nil)
    }
}
