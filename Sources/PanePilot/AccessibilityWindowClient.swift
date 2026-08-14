import AppKit
import ApplicationServices
import PanePilotCore

struct ManagedWindow {
    var element: AXUIElement
    var rect: CGRect
}

final class AccessibilityWindowClient {
    private let systemWide = AXUIElementCreateSystemWide()

    func isTrusted(prompt: Bool) -> Bool {
        let key = "AXTrustedCheckOptionPrompt"
        return AXIsProcessTrustedWithOptions([key: prompt] as CFDictionary)
    }

    func focusedWindow() -> ManagedWindow? {
        if let appWindow = focusedWindowFromFrontmostApplication() {
            return appWindow
        }

        var value: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(systemWide, kAXFocusedWindowAttribute as CFString, &value)
        guard status == .success, let element = value else {
            return nil
        }
        let window = element as! AXUIElement
        guard let rect = rect(for: window) else {
            return nil
        }
        return ManagedWindow(element: window, rect: rect)
    }

    private func focusedWindowFromFrontmostApplication() -> ManagedWindow? {
        guard let app = NSWorkspace.shared.frontmostApplication else {
            return nil
        }
        return window(forProcessIdentifier: app.processIdentifier)
    }

    func window(forProcessIdentifier processIdentifier: pid_t) -> ManagedWindow? {
        let appElement = AXUIElementCreateApplication(processIdentifier)
        for attribute in [kAXFocusedWindowAttribute, kAXMainWindowAttribute] {
            var value: CFTypeRef?
            let status = AXUIElementCopyAttributeValue(appElement, attribute as CFString, &value)
            guard status == .success, let element = value else {
                continue
            }
            let window = element as! AXUIElement
            if let rect = rect(for: window) {
                return ManagedWindow(element: window, rect: rect)
            }
        }
        return windows(forProcessIdentifier: processIdentifier).first
    }

    func windows(forProcessIdentifier processIdentifier: pid_t) -> [ManagedWindow] {
        let appElement = AXUIElementCreateApplication(processIdentifier)
        var windowsRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef) == .success,
           let windows = windowsRef as? NSArray {
            return windows.compactMap { window in
                let window = window as! AXUIElement
                guard let rect = rect(for: window) else {
                    return nil
                }
                return ManagedWindow(element: window, rect: rect)
            }
        }
        return []
    }

    func rect(for window: ManagedWindow) -> CGRect? {
        rect(for: window.element)
    }

    func displays() -> [DisplayFrame] {
        let screens = NSScreen.screens
        guard let primaryScreenFrame = screens.first?.frame else { return [] }

        return screens
            .sorted { $0.frame.minX == $1.frame.minX ? $0.frame.minY > $1.frame.minY : $0.frame.minX < $1.frame.minX }
            .enumerated()
            .map { index, screen in
                DisplayFrame(
                    id: screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")].map(String.init(describing:)) ?? "\(index)",
                    visibleFrame: DisplayGeometry.accessibilityFrame(
                        fromCocoaFrame: screen.visibleFrame,
                        primaryScreenFrame: primaryScreenFrame
                    )
                )
            }
    }

    func activeDisplayID(for rect: CGRect) -> String? {
        DisplayGeometry.activeDisplay(in: displays(), for: rect)?.id
    }

    func set(_ rect: CGRect, for window: ManagedWindow) -> Bool {
        var origin = rect.origin
        var size = rect.size
        guard
            let position = AXValueCreate(.cgPoint, &origin),
            let axSize = AXValueCreate(.cgSize, &size)
        else {
            return false
        }

        return withEnhancedUserInterfaceDisabled(for: window.element) {
            var succeeded = true
            for attribute in WindowFrameWritePlan.constrainedApplicationOrder {
                let status = switch attribute {
                case .size:
                    AXUIElementSetAttributeValue(
                        window.element,
                        kAXSizeAttribute as CFString,
                        axSize
                    )
                case .position:
                    AXUIElementSetAttributeValue(
                        window.element,
                        kAXPositionAttribute as CFString,
                        position
                    )
                }
                succeeded = status == .success && succeeded
            }
            return succeeded
        }
    }

    private func withEnhancedUserInterfaceDisabled<T>(
        for window: AXUIElement,
        operation: () -> T
    ) -> T {
        var processIdentifier: pid_t = 0
        guard AXUIElementGetPid(window, &processIdentifier) == .success else {
            return operation()
        }

        let application = AXUIElementCreateApplication(processIdentifier)
        let attribute = "AXEnhancedUserInterface" as CFString
        var value: CFTypeRef?
        let wasEnabled = AXUIElementCopyAttributeValue(application, attribute, &value) == .success
            && value as? Bool == true

        if wasEnabled {
            AXUIElementSetAttributeValue(application, attribute, kCFBooleanFalse)
        }
        defer {
            if wasEnabled {
                AXUIElementSetAttributeValue(application, attribute, kCFBooleanTrue)
            }
        }
        return operation()
    }

    private func rect(for element: AXUIElement) -> CGRect? {
        var positionRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        guard
            AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionRef) == .success,
            AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeRef) == .success,
            let positionRef,
            let sizeRef
        else {
            return nil
        }

        var origin = CGPoint.zero
        var size = CGSize.zero
        AXValueGetValue(positionRef as! AXValue, .cgPoint, &origin)
        AXValueGetValue(sizeRef as! AXValue, .cgSize, &size)
        return CGRect(origin: origin, size: size)
    }
}
