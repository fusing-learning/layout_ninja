//
//  main.swift
//  windowmanager
//
//  Created by Fu Sing Tan on 26/7/25.
//
import Foundation
import ApplicationServices
import Cocoa

struct WindowInfo: Codable {
    let appName: String
    let windowTitle: String
    let x: CGFloat
    let y: CGFloat
    let width: CGFloat
    let height: CGFloat
}

class WindowManager {
    
    func checkAccessibilityPermission() -> Bool {
        let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        let options = [checkOptPrompt: true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options as CFDictionary?)
        
        if !accessEnabled {
            print("⚠️  Accessibility permission required!")
            print("Please grant accessibility permission in System Preferences > Security & Privacy > Privacy > Accessibility")
            print("Add this application and try again.")
        }
        
        return accessEnabled
    }
    
    func saveWindowPositions(to filePath: String) {
        guard checkAccessibilityPermission() else { return }
        
        var windowInfos: [WindowInfo] = []
        
        // Get all running applications
        let runningApps = NSWorkspace.shared.runningApplications
        
        for app in runningApps {
            guard app.activationPolicy == .regular,
                  let bundleId = app.bundleIdentifier,
                  let appName = app.localizedName else { continue }
            
            let appRef = AXUIElementCreateApplication(app.processIdentifier)
            
            // Get windows for this application
            var windowsRef: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowsRef)
            
            if result == .success,
               let windows = windowsRef as? [AXUIElement] {
                
                for window in windows {
                    if let windowInfo = getWindowInfo(window: window, appName: appName) {
                        windowInfos.append(windowInfo)
                    }
                }
            }
        }
        
        // Save to JSON file
        do {
            let jsonData = try JSONEncoder().encode(windowInfos)
            try jsonData.write(to: URL(fileURLWithPath: filePath))
            print("✅ Saved \(windowInfos.count) window positions to \(filePath)")
        } catch {
            print("❌ Error saving window positions: \(error)")
        }
    }
    
    func restoreWindowPositions(from filePath: String) {
        guard checkAccessibilityPermission() else { return }
        
        // Read JSON file
        guard let jsonData = try? Data(contentsOf: URL(fileURLWithPath: filePath)),
              let windowInfos = try? JSONDecoder().decode([WindowInfo].self, from: jsonData) else {
            print("❌ Error reading window positions from \(filePath)")
            return
        }
        
        let runningApps = NSWorkspace.shared.runningApplications
        var restoredCount = 0
        
        for windowInfo in windowInfos {
            // Find the application
            if let app = runningApps.first(where: { $0.localizedName == windowInfo.appName }) {
                let appRef = AXUIElementCreateApplication(app.processIdentifier)
                
                // Get windows for this application
                var windowsRef: CFTypeRef?
                let result = AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowsRef)
                
                if result == .success,
                   let windows = windowsRef as? [AXUIElement] {
                    
                    // Find matching window by title
                    for window in windows {
                        var titleRef: CFTypeRef?
                        AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef)
                        
                        if let title = titleRef as? String,
                           title == windowInfo.windowTitle {
                            
                            // Set position and size
                            let position = CGPoint(x: windowInfo.x, y: windowInfo.y)
                            let size = CGSize(width: windowInfo.width, height: windowInfo.height)
                            
                            setWindowPosition(window: window, position: position)
                            setWindowSize(window: window, size: size)
                            restoredCount += 1
                            break
                        }
                    }
                }
            }
        }
        
        print("✅ Restored \(restoredCount) window positions")
    }
    
    private func getWindowInfo(window: AXUIElement, appName: String) -> WindowInfo? {
        var titleRef: CFTypeRef?
        var positionRef: CFTypeRef?
        var sizeRef: CFTypeRef?
        
        // Get window title
        AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &titleRef)
        guard let title = titleRef as? String, !title.isEmpty else { return nil }
        
        // Get window position
        AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionRef)
        guard let positionValue = positionRef else { return nil }
        
        var position = CGPoint.zero
        if !AXValueGetValue(positionValue as! AXValue, .cgPoint, &position) {
            return nil
        }
        
        // Get window size
        AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeRef)
        guard let sizeValue = sizeRef else { return nil }
        
        var size = CGSize.zero
        if !AXValueGetValue(sizeValue as! AXValue, .cgSize, &size) {
            return nil
        }
        
        return WindowInfo(
            appName: appName,
            windowTitle: title,
            x: position.x,
            y: position.y,
            width: size.width,
            height: size.height
        )
    }
    
    private func setWindowPosition(window: AXUIElement, position: CGPoint) {
        var mutablePosition = position
        let positionValue = AXValueCreate(.cgPoint, &mutablePosition)!
        AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, positionValue)
    }
    
    private func setWindowSize(window: AXUIElement, size: CGSize) {
        var mutableSize = size
        let sizeValue = AXValueCreate(.cgSize, &mutableSize)!
        AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, sizeValue)
    }
}

// MARK: - Main Program
func main() {
    let windowManager = WindowManager()
    let arguments = CommandLine.arguments
    
    guard arguments.count >= 2 else {
        print("Usage:")
        print("  \(arguments[0]) save [filename]    - Save current window positions")
        print("  \(arguments[0]) restore [filename] - Restore saved window positions")
        print("\nDefault filename: window_positions.json")
        exit(1)
    }
    
    let command = arguments[1].lowercased()
    let filename = arguments.count > 2 ? arguments[2] : "window_positions.json"
    let filePath = FileManager.default.currentDirectoryPath + "/" + filename
    
    switch command {
    case "save":
        windowManager.saveWindowPositions(to: filePath)
    case "restore":
        windowManager.restoreWindowPositions(from: filePath)
    default:
        print("❌ Unknown command: \(command)")
        print("Use 'save' or 'restore'")
        exit(1)
    }
}

main()
