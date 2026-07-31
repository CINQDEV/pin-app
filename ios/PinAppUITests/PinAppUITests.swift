import XCTest

final class PinAppUITests: XCTestCase {
    func testTapIslandTitleNavigatesToDetail() throws {
        let app = XCUIApplication()
        app.launch()

        let islandsTab = app.tabBars.buttons["Islands"]
        XCTAssertTrue(islandsTab.waitForExistence(timeout: 5), "Islands tab not found")
        islandsTab.tap()

        let list = app.collectionViews.firstMatch
        XCTAssertTrue(list.waitForExistence(timeout: 10), "Islands list did not appear")

        let titleLinks = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'islandTitleLink_'"))
        XCTAssertTrue(titleLinks.element(boundBy: 0).waitForExistence(timeout: 30), "No island title links appeared — list may still be loading or rows aren't accessible as buttons")

        let firstLink = titleLinks.element(boundBy: 0)
        let linkLabel = firstLink.label
        firstLink.tap()

        let showOnMap = app.buttons["Show on Map"]
        let navigated = showOnMap.waitForExistence(timeout: 5)

        if !navigated {
            print("DEBUG: tapped title '\(linkLabel)' but detail screen did not appear")
            print("DEBUG: app hierarchy:\n\(app.debugDescription)")
        }
        XCTAssertTrue(navigated, "Tapping island title '\(linkLabel)' did not navigate to detail screen")
    }

    func testPinnedUnpinnedFilter() throws {
        let app = XCUIApplication()
        app.launch()

        app.tabBars.buttons["Islands"].tap()

        let list = app.collectionViews.firstMatch
        XCTAssertTrue(list.waitForExistence(timeout: 10), "Islands list did not appear")

        let titleLinks = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'islandTitleLink_'"))
        XCTAssertTrue(titleLinks.element(boundBy: 0).waitForExistence(timeout: 30), "List never populated")
        let unfilteredCount = titleLinks.count

        let filterMenu = app.buttons["islandFilterMenu"]
        XCTAssertTrue(filterMenu.exists, "Filter menu button not found")
        filterMenu.tap()

        let pinnedOption = app.buttons["Pinned"]
        guard pinnedOption.waitForExistence(timeout: 5) else {
            print("DEBUG: app hierarchy after tapping filter menu:\n\(app.debugDescription)")
            XCTFail("Pinned filter option not found in menu")
            return
        }
        pinnedOption.tap()

        // Give the list a moment to re-filter, then re-count.
        Thread.sleep(forTimeInterval: 1)
        let pinnedCount = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'islandTitleLink_'")).count
        XCTAssertLessThanOrEqual(pinnedCount, unfilteredCount, "Pinned filter should not show more islands than unfiltered")

        XCTAssertTrue(filterMenu.waitForExistence(timeout: 5), "Filter menu button not found before reopening")
        filterMenu.tap()
        let unpinnedOption = app.buttons["Unpinned"]
        guard unpinnedOption.waitForExistence(timeout: 5) else {
            print("DEBUG: app hierarchy after reopening filter menu:\n\(app.debugDescription)")
            XCTFail("Unpinned filter option not found in menu")
            return
        }
        unpinnedOption.tap()

        Thread.sleep(forTimeInterval: 1)
        let unpinnedCount = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'islandTitleLink_'")).count
        // Note: List virtualizes off-screen rows, so these counts only reflect what's
        // currently rendered in the viewport, not the true dataset totals — just confirm
        // the filter UI is interactive and doesn't show more than the unfiltered view did.
        XCTAssertLessThanOrEqual(unpinnedCount, unfilteredCount, "Unpinned filter should not show more islands than unfiltered")
    }

    func testMapMarkerTapShowsCalloutAndNavigatesToDetail() throws {
        let app = XCUIApplication()
        app.launch()

        app.tabBars.buttons["Islands"].tap()

        let list = app.collectionViews.firstMatch
        XCTAssertTrue(list.waitForExistence(timeout: 10), "Islands list did not appear")

        let mapButtons = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'islandMapButton_'"))
        XCTAssertTrue(mapButtons.element(boundBy: 0).waitForExistence(timeout: 30), "No island map buttons appeared")
        mapButtons.element(boundBy: 0).tap()

        // Tapping a row's map button should switch to the Map tab and select that island.
        let callout = app.buttons["mapSelectionCallout"]
        guard callout.waitForExistence(timeout: 5) else {
            print("DEBUG: app hierarchy after tapping map button:\n\(app.debugDescription)")
            XCTFail("Map selection callout did not appear after tapping a row's map button")
            return
        }

        callout.tap()

        let showOnMap = app.buttons["Show on Map"]
        let navigated = showOnMap.waitForExistence(timeout: 5)
        if !navigated {
            print("DEBUG: app hierarchy after tapping callout:\n\(app.debugDescription)")
        }
        XCTAssertTrue(navigated, "Tapping the map callout did not navigate to the detail screen")
    }
}
