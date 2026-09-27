// AppGroupStore tests, appended to the library/stats suite runner coverage.
// Build & run (macOS host):
//   swiftc ios/SpeedReader/Core/AppGroupStore.swift ios/Tests/AppGroupStoreTests.swift \
//          -o /tmp/appgroup_tests && /tmp/appgroup_tests
import Foundation

@main
enum AppGroupStoreTestRunner {

    static func main() {
        var failures = 0
        var passed = 0

        func expect<T: Equatable>(_ name: String, _ actual: T, _ expected: T) {
            if actual == expected {
                passed += 1
            } else {
                failures += 1
                print("FAIL: \(name) — expected \(expected), got \(actual)")
            }
        }

        AppGroupStore.savePending(text: "", title: nil)
        expect("empty text yields no pending share", AppGroupStore.takePendingText() == nil, true)

        AppGroupStore.savePending(text: "   \n\t  ", title: "x")
        expect("whitespace-only text yields no pending share", AppGroupStore.takePendingText() == nil, true)

        AppGroupStore.savePending(text: "Shared article body.", title: "Article")
        let first = AppGroupStore.takePendingText()
        expect("pending text roundtrips", first?.text, "Shared article body.")
        expect("pending title roundtrips", first?.title, "Article")
        expect("take clears the slot", AppGroupStore.takePendingText() == nil, true)

        AppGroupStore.savePending(text: "Second share.", title: nil)
        let second = AppGroupStore.takePendingText()
        expect("nil title roundtrips as nil", second?.title == nil, true)
        expect("second share text", second?.text, "Second share.")

        if failures == 0 {
            print("All \(passed) app-group tests passed.")
            exit(0)
        } else {
            print("\(failures) of \(passed + failures) app-group tests FAILED.")
            exit(1)
        }
    }
}
