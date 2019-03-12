//
//  LastActivityRecorder.swift
//
//  Created by Russ Shanahan on 3/11/19.
//  Copyright © 2019 Front Pocket Software LLC. All rights reserved.
//

import Foundation

// A thread-safe way to keep track of how long it's been since an event happened.
class LastActivityRecorder {
    private var lastActivity: DispatchTime
    private var lastActivitySemaphor = DispatchSemaphore(value: 1)

    init() {
        lastActivity = DispatchTime.now()
    }
    
    // Reset the last time we saw an event to `now()`
    public func touch() {
        lastActivitySemaphor.wait()
        lastActivity = DispatchTime.now()
        lastActivitySemaphor.signal()
    }
    
    // Report the number of seconds since the last time an event was recorded via `touch()`
    public func elapsedTime() -> Double {
        self.lastActivitySemaphor.wait()
        let elapsedTime = DispatchTime.now().uptimeNanoseconds - self.lastActivity.uptimeNanoseconds
        self.lastActivitySemaphor.signal()
        return Double(elapsedTime) / Double(1_000_000_000)
    }
}
