import XCTest

final class SmokeTests: XCTestCase {
    @MainActor
    func testSolveUndoAndDaySheetFlow() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-seed", "-inMemory"]
        app.launch()
        snap("1-open")

        let button = app.buttons["solve-button"]
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.tap()
        snap("2-burst")
        XCTAssertTrue(app.staticTexts["Streak secured."].waitForExistence(timeout: 2)
            || app.staticTexts["Day one, done."].exists)
        sleep(2)
        snap("3-solved")

        button.tap()
        XCTAssertTrue(app.buttons["Undo"].waitForExistence(timeout: 2))
        app.buttons["Undo"].tap()

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let yesterday = formatter.string(from: Calendar.current.date(byAdding: .day, value: -1, to: .now)!)
        let cell = app.buttons["day-\(yesterday)"]
        XCTAssertTrue(cell.waitForExistence(timeout: 2))
        // The heatmap card sits below the hero card and can be out of the visible
        // viewport (and thus not hittable) on first layout. Scroll it into view
        // before tapping — existence in the hierarchy doesn't guarantee hittability.
        if !cell.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(cell.waitForExistence(timeout: 2))
        cell.tap()
        // `.sheet(item:)` slides up with an animation; tap() returns once the event is
        // dispatched, not once the presentation settles, so wait for a sheet element
        // before capturing — otherwise the screenshot can catch the home screen mid-transition.
        let addSolveButton = app.buttons["Add solve"]
        XCTAssertTrue(addSolveButton.waitForExistence(timeout: 2))
        snap("4-day-sheet")

        addSolveButton.tap()
        let field = app.descendants(matching: .any)["editor-note"]
        XCTAssertTrue(field.waitForExistence(timeout: 2))
        field.tap()
        field.typeText("Coin Change | DP")
        app.buttons["Save"].tap()
        sleep(1)
        snap("5-day-sheet-after-add")
    }

    @MainActor
    private func snap(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
