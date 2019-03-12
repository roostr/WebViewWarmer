# WebViewWarmer

## Description

Have you ever wished that a UIWebView wouldn't take a few extra frames to load the first time you access it?

This simple utility waits for your app to go completely idle on the main thread for a short duration of time (by default, 0.5 seconds). "Completely idle" means that there have been no animations, no UI updates, and no touch events. When this idle period is detected, it performs a simple operation to load a UIWebView off-screen. This operation ensures that the next time you display a UIWebView, it will be ready to load without any stutter.

## Usage

### Obj-C

```
[WebViewWarmer requestWarmingWhenIdle];
```

### Swift

```
WebViewWarmer.requestWarmingWhenIdle()
```

## License

MIT
