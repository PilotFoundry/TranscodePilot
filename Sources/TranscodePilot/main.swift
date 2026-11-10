import AppKit
import SwiftUI

extension NSToolbarItem.Identifier {
    static let addFiles = NSToolbarItem.Identifier("TranscodePilotAddFiles")
    static let outputFolder = NSToolbarItem.Identifier("TranscodePilotOutputFolder")
}

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate,
    NSToolbarDelegate, NSToolbarItemValidation {
    let model = AppModel()
    var window: NSWindow!
    private var terminationInProgress = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        if let icon = AppIcon.image {
            // Dock tiles use the running app's application icon; set it
            // explicitly so a rebuilt icns does not fall back to the generic icon.
            NSApp.applicationIconImage = icon
        }
        configureWindow()
        configureMenus()
        NSApp.activate(ignoringOtherApps: true)
    }

    private func configureWindow() {
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 900, height: 620),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered, defer: false)
        window.title = "TranscodePilot"
        window.contentViewController = NSHostingController(rootView: MainView(model: model))
        window.delegate = self
        _ = window.setFrameAutosaveName("TranscodePilotMainWindow")

        let toolbar = NSToolbar(identifier: "TranscodePilotMainToolbar")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        toolbar.allowsUserCustomization = false
        toolbar.autosavesConfiguration = false
        window.toolbar = toolbar
        window.toolbarStyle = .unified

        if !window.setFrameUsingName("TranscodePilotMainWindow") {
            window.center()
        }
        window.makeKeyAndOrderFront(nil)
    }

    private func configureMenus() {
        let mainMenu = NSMenu()
        mainMenu.addItem(makeAppMenu())
        mainMenu.addItem(makeFileMenu())
        mainMenu.addItem(makeEditMenu())
        mainMenu.addItem(makeWindowMenu())
        mainMenu.addItem(makeHelpMenu())
        NSApp.mainMenu = mainMenu
    }

    private func makeAppMenu() -> NSMenuItem {
        let (item, menu) = makeMenu(title: "TranscodePilot")
        let about = menu.addItem(withTitle: L("About TranscodePilot"), action: #selector(about), keyEquivalent: "")
        about.target = self
        menu.addItem(.separator())

        let servicesItem = NSMenuItem(title: L("Services"), action: nil, keyEquivalent: "")
        let servicesMenu = NSMenu(title: L("Services"))
        servicesItem.submenu = servicesMenu
        menu.addItem(servicesItem)
        NSApp.servicesMenu = servicesMenu
        menu.addItem(.separator())

        let hide = menu.addItem(withTitle: L("Hide TranscodePilot"), action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        hide.target = NSApp
        let hideOthers = menu.addItem(withTitle: L("Hide Others"), action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.target = NSApp
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        let showAll = menu.addItem(withTitle: L("Show All"), action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        showAll.target = NSApp
        menu.addItem(.separator())

        let quit = menu.addItem(withTitle: L("Quit TranscodePilot"), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.target = NSApp
        return item
    }

    private func makeFileMenu() -> NSMenuItem {
        let (item, menu) = makeMenu(title: L("File"))
        let add = menu.addItem(withTitle: L("Add Files…"), action: #selector(addFilesFromMenu), keyEquivalent: "o")
        add.target = self
        menu.addItem(.separator())
        let close = menu.addItem(withTitle: L("Close"), action: #selector(closeWindow), keyEquivalent: "w")
        close.target = self
        return item
    }

    private func makeEditMenu() -> NSMenuItem {
        let (item, menu) = makeMenu(title: L("Edit"))
        for (title, action, key) in [("Cut", "cut:", "x"), ("Copy", "copy:", "c"), ("Paste", "paste:", "v"), ("Select All", "selectAll:", "a")] {
            menu.addItem(withTitle: L(title), action: Selector(action), keyEquivalent: key)
        }
        return item
    }

    private func makeWindowMenu() -> NSMenuItem {
        let (item, menu) = makeMenu(title: L("Window"))
        let minimize = menu.addItem(withTitle: L("Minimize"), action: #selector(minimizeWindow), keyEquivalent: "m")
        minimize.target = self
        let zoom = menu.addItem(withTitle: L("Zoom"), action: #selector(zoomWindow), keyEquivalent: "")
        zoom.target = self
        menu.addItem(.separator())
        let front = menu.addItem(withTitle: L("Bring All to Front"), action: #selector(NSApplication.arrangeInFront(_:)), keyEquivalent: "")
        front.target = NSApp
        NSApp.windowsMenu = menu
        return item
    }

    private func makeHelpMenu() -> NSMenuItem {
        let (item, menu) = makeMenu(title: L("Help"))
        let help = menu.addItem(withTitle: L("TranscodePilot Help"), action: #selector(showHelp), keyEquivalent: "?")
        help.target = self
        return item
    }

    private func makeMenu(title: String) -> (NSMenuItem, NSMenu) {
        let item = NSMenuItem()
        let menu = NSMenu(title: title)
        item.submenu = menu
        return (item, menu)
    }

    @objc func addFilesFromMenu() {
        model.chooseFiles()
    }

    @objc private func addFilesFromToolbar() {
        model.chooseFiles()
    }

    @objc private func chooseOutputFolder() {
        model.chooseFolder()
    }

    @objc private func closeWindow() {
        window?.performClose(nil)
    }

    @objc private func minimizeWindow() {
        window?.performMiniaturize(nil)
    }

    @objc private func zoomWindow() {
        window?.performZoom(nil)
    }

    @objc private func showHelp() {
        let alert = NSAlert()
        alert.messageText = L("TranscodePilot Help")
        alert.informativeText = L("Supported inputs: SVG, PNG, JPEG, HEIC, MP4. Outputs: PNG, JPEG, MP3. Files stay on this Mac; sources and existing output are preserved.")
        alert.addButton(withTitle: L("OK"))
        alert.runModal()
    }

    // MARK: - Toolbar

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.addFiles, .flexibleSpace, .outputFolder]
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.addFiles, .flexibleSpace, .space, .outputFolder]
    }

    func toolbar(_ toolbar: NSToolbar,
                 itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        switch itemIdentifier {
        case .addFiles:
            return makeToolbarItem(identifier: .addFiles,
                                   symbol: "plus",
                                   label: L("Add files"),
                                   action: #selector(addFilesFromToolbar))
        case .outputFolder:
            return makeToolbarItem(identifier: .outputFolder,
                                   symbol: "folder",
                                   label: L("Output folder"),
                                   action: #selector(chooseOutputFolder))
        default:
            return nil
        }
    }

    private func makeToolbarItem(identifier: NSToolbarItem.Identifier,
                                 symbol: String,
                                 label: String,
                                 action: Selector) -> NSToolbarItem {
        let item = NSToolbarItem(itemIdentifier: identifier)
        item.label = label
        item.paletteLabel = label
        item.toolTip = label
        item.image = NSImage(systemSymbolName: symbol, accessibilityDescription: label)
        item.target = self
        item.action = action
        item.isBordered = true
        return item
    }

    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        switch item.itemIdentifier {
        case .addFiles:
            // New files join the queue for the next run; the active job list is
            // already snapshotted.
            return true
        case .outputFolder:
            return !model.running
        default:
            return true
        }
    }

    // MARK: - App delegate

    @objc func about() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
        NSApp.orderFrontStandardAboutPanel(options: [.applicationName: "TranscodePilot",
            .applicationVersion: version,
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
        scheduleTerminationCheck(deadline: Date().addingTimeInterval(5))
        return .terminateLater
    }

    private func scheduleTerminationCheck(deadline: Date) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            MainActor.assumeIsolated {
                guard let self, self.terminationInProgress else { return }
                if !self.model.running || Date() >= deadline {
                    self.finishTermination()
                } else {
                    self.scheduleTerminationCheck(deadline: deadline)
                }
            }
        }
    }

    private func finishTermination() {
        guard terminationInProgress else { return }
        terminationInProgress = false
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
}

MainActor.assumeIsolated {
    let app = NSApplication.shared
    let delegate = AppDelegate()
    app.delegate = delegate
    withExtendedLifetime(delegate) { app.run() }
}
