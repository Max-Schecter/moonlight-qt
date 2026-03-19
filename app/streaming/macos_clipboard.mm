#include "macos_clipboard.h"

#include <AppKit/AppKit.h>
#include <dispatch/dispatch.h>

namespace {
template<typename Fn>
auto onMainThread(Fn&& fn) -> decltype(fn()) {
    using result_t = decltype(fn());
    if ([NSThread isMainThread]) {
        @autoreleasepool {
            return fn();
        }
    }

    __block result_t result {};
    dispatch_sync(dispatch_get_main_queue(), ^{
        @autoreleasepool {
            result = fn();
        }
    });
    return result;
}

}

namespace macos_clipboard {
bool isAvailable() {
    return onMainThread([]() {
        return [NSPasteboard generalPasteboard] != nil;
    });
}

std::uint64_t getChangeCount() {
    return onMainThread([]() -> std::uint64_t {
        NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
        return pasteboard != nil ? (std::uint64_t) pasteboard.changeCount : 0;
    });
}

std::string getText() {
    return onMainThread([]() -> std::string {
        NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
        if (pasteboard == nil) {
            return {};
        }

        NSString* text = [pasteboard stringForType:NSPasteboardTypeString];
        if (text == nil) {
            return {};
        }

        return std::string(text.UTF8String ?: "");
    });
}

void setText(const std::string& text) {
    if ([NSThread isMainThread]) {
        @autoreleasepool {
            NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
            if (pasteboard == nil) {
                return;
            }

            [pasteboard clearContents];
            NSString* nsText = [[NSString alloc] initWithBytes:text.data()
                                                        length:text.size()
                                                      encoding:NSUTF8StringEncoding];
            if (nsText != nil) {
                [pasteboard setString:nsText forType:NSPasteboardTypeString];
            }
        }
        return;
    }

    std::string copy = text;
    dispatch_sync(dispatch_get_main_queue(), ^{
        @autoreleasepool {
            NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
            if (pasteboard == nil) {
                return;
            }

            [pasteboard clearContents];
            NSString* nsText = [[NSString alloc] initWithBytes:copy.data()
                                                        length:copy.size()
                                                      encoding:NSUTF8StringEncoding];
            if (nsText != nil) {
                [pasteboard setString:nsText forType:NSPasteboardTypeString];
            }
        }
    });
}
}
