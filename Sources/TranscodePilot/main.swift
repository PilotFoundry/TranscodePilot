import AppKit
import SwiftUI

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    let model = AppModel()
    var window: NSWindow!
    private var terminationInProgress = false
    private var terminationTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 900, height: 620),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        window.title = "TranscodePilot"
        window.contentViewController = NSHostingController(rootView: MainView(model: model))
        window.delegate = self
        window.center()
        window.makeKeyAndOrderFront(nil)
        let menu = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: L("About TranscodePilot"), action: #selector(about), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: L("Quit TranscodePilot"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        menu.addItem(appItem)
        let editItem = NSMenuItem()
        let editMenu = NSMenu(title: L("Edit"))
        for (title, action, key) in [("Cut", "cut:", "x"), ("Copy", "copy:", "c"), ("Paste", "paste:", "v"), ("Select All", "selectAll:", "a")] {
            editMenu.addItem(withTitle: L(title), action: Selector(action), keyEquivalent: key)
        }
        editItem.submenu = editMenu
        menu.addItem(editItem)
        NSApp.mainMenu = menu
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc func about() {
        NSApp.orderFrontStandardAboutPanel(options: [.applicationName: "TranscodePilot", .applicationVersion: "0.1.0",
            .credits: NSAttributedString(string: "PilotFoundry · MIT\n" + L("Local media conversion") + "\nFFmpeg / librsvg: external development dependencies")])
    }

    func application(_ sender: NSApplication, openFiles filenames: [String]) {
        model.add(filenames.map { URL(fileURLWithPath: $0) })
        sender.reply(toOpenOrPrint: .success)
        window?.makeKeyAndOrderFront(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if terminationInProgress { return .terminateLater }
        guard model.running else { return .terminateNow }
        // Cancel, let the worker stop its child process and clean its temporary
        // output, then finish the quit. The timeout keeps a stuck bitmap stage
        // from wedging termination forever.
        terminationInProgress = true
        model.cancel()
        let deadline = Date().addingTimeInterval(5)
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            MainActor.assumeIsolated {
                guard let self, self.terminationInProgress else {
                    timer.invalidate()
                    return
                }
                if !self.model.running || Date() >= deadline {
                    self.finishTermination()
                }
            }
        }
        terminationTimer = timer
        return .terminateLater
    }

    private func finishTermination() {
        guard terminationInProgress else { return }
        terminationInProgress = false
        terminationTimer?.invalidate()
        terminationTimer = nil
        NSApp.reply(toApplicationShouldTerminate: true)
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if terminationInProgress { return true }
        guard model.running else { return true }
        let alert = NSAlert()
        alert.messageText = L("Conversion in progress")
        alert.informativeText = L("Wait for the current conversion to finish or cancel it first.")
        alert.addButton(withTitle: L("OK"))
        alert.runModal()
        return false
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        terminationTimer?.invalidate()
        terminationTimer = nil
    }
}

MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    withExtendedLifetime(delegate) { app.run() }
}
