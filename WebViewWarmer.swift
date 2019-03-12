//
//  WebViewWarmer.swift
//
//  Created by Russ Shanahan on 3/8/19.
//  Copyright © 2019 Front Pocket Software LLC. All rights reserved.
//

import Foundation

@objc public class WebViewWarmer: NSObject {
    
    // Kick off a request to load a UIWebView as soon as a sufficient period of idleness has elapsed.
    @objc public static func requestWarmingWhenIdle() {
        let _ = instance
    }
    
    static private let instance = WebViewWarmer()
    
    private let lastActivity = LastActivityRecorder() // A way to track how long it's been since an event was seen
    private let requiredIdleDelay: Double = 0.5       // The duration, in seconds, the system must be completely idle before we try to load the UIWebView
    private let timerSlop:         Double = 0.000_050 // The duration, in seconds, of additional sleep padding to ensure we don't wake up from sleep too early
    private let webviewLifetime:   Double = 5.0       // The duration, in seconds, of time that the UIWebView object should be loaded in memory

    private override init() {
        super.init()

        // Install an observer to monitor all activity on main thread (touch events, animations, etc)
        guard let runLoopObserver = installRunLoopObserver(observerClosure: { (observer: CFRunLoopObserver?, activity: CFRunLoopActivity) in
            self.lastActivity.touch() // Update the "last-event-seen" time whenever there's an event
        }) else {
            print("Error: Could not install run loop observer.")
            return
        }

        let backgroundQueue = OperationQueue()
        backgroundQueue.addOperation {
            while true {
                // How long has it been since we've seen an event on the main thread?
                let elapsedTime = self.lastActivity.elapsedTime()
                
                if elapsedTime < self.requiredIdleDelay {
                    // We have not yet had a sufficiently long period of inactivity. Sleep for as much time
                    // as it would take to hit that duration of inactivity, and then check again.
                    usleep(UInt32((self.requiredIdleDelay - elapsedTime + self.timerSlop) * 1_000_000))
                    continue
                }
                
                // We've seen a sufficiently long period of inactivity.
                OperationQueue.main.addOperation {
                    // We no longer need to observe the main queue's run loop.
                    self.removeRunLoopObserver(observer: runLoopObserver)

                    print("Caching the webview.")
                    var webView: UIWebView? = UIWebView(frame: .zero)
                    webView?.loadHTMLString("<html></html>", baseURL: nil)
                    
                    // Keep this WebView object alive for a brief duration so it can fully initialize its web engine stuff
                    backgroundQueue.addOperation {
                        usleep(UInt32(self.webviewLifetime * 1_000_000))
                        OperationQueue.main.addOperation {
                            webView?.alpha = 0.0 // Perform an operation on the webView to silence a warning about it never being used.
                            webView = nil
                        }
                    }
                }
                break
            }
        }
    }

    // Install a run loop observer into the main thread's run loop (for all run loop modes)
    private func installRunLoopObserver(observerClosure: @escaping (CFRunLoopObserver?, CFRunLoopActivity) -> Void) -> CFRunLoopObserver? {
        guard let observer = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, CFRunLoopActivity.allActivities.rawValue, true, 0, observerClosure) else {
            return nil
        }
        CFRunLoopAddObserver(CFRunLoopGetMain(), observer, .commonModes)
        return observer
    }

    // Remove the run loop observer
    private func removeRunLoopObserver(observer: CFRunLoopObserver) {
        CFRunLoopRemoveObserver(CFRunLoopGetMain(), observer, .commonModes)
    }
}
