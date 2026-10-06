import Foundation

enum PageSelectionChecks {
    static func run() {
        selectReplacesSelection()
        toggleAddsPageAndMovesAnchor()
        toggleRemovesSelectedPage()
        extendSelectsRangeForward()
        extendSelectsRangeBackward()
        extendKeepsAnchorSoRangeCanShrink()
        extendWithoutAnchorSelectsPage()
        extendToUnknownPageSelectsIt()
        stepMovesToNeighbour()
        stepStopsAtLastPage()
        stepStopsAtFirstPage()
        stepWithoutAnchorForwardPicksFirstPage()
        stepWithoutAnchorBackwardPicksLastPage()
        stepInEmptyListClears()
    }

    private static let pages = (0..<5).map { _ in UUID() }
    private static let stranger = UUID()

    private static func page(_ index: Int) -> UUID { pages[index] }

    private static func selection(_ steps: (inout PageSelection) -> Void) -> PageSelection {
        var selection = PageSelection()
        steps(&selection)
        return selection
    }

    static func selectReplacesSelection() {
        let selection = selection {
            $0.toggle(page(0))
            $0.toggle(page(1))
            $0.select(page(3))
        }
        expect(selection.ids == [page(3)], "select replaces the selected pages with one page")
        expect(selection.anchor == page(3), "select makes the page the anchor")
    }

    static func toggleAddsPageAndMovesAnchor() {
        let selection = selection {
            $0.select(page(0))
            $0.toggle(page(2))
        }
        expect(selection.ids == [page(0), page(2)], "toggle adds a page and keeps the others")
        expect(selection.anchor == page(2), "toggle moves the anchor to the toggled page")
    }

    static func toggleRemovesSelectedPage() {
        let selection = selection {
            $0.select(page(0))
            $0.toggle(page(2))
            $0.toggle(page(0))
        }
        expect(selection.ids == [page(2)], "toggle removes a selected page")
        expect(selection.anchor == page(0), "toggle moves the anchor to a removed page too")
    }

    static func extendSelectsRangeForward() {
        let selection = selection {
            $0.select(page(1))
            $0.extend(to: page(3), in: pages)
        }
        expect(selection.ids == [page(1), page(2), page(3)], "extend selects every page from the anchor forward")
    }

    static func extendSelectsRangeBackward() {
        let selection = selection {
            $0.select(page(3))
            $0.extend(to: page(0), in: pages)
        }
        expect(selection.ids == Set(pages[0...3]), "extend selects every page from the anchor backward")
    }

    static func extendKeepsAnchorSoRangeCanShrink() {
        let selection = selection {
            $0.select(page(1))
            $0.extend(to: page(4), in: pages)
            $0.extend(to: page(2), in: pages)
        }
        expect(selection.ids == [page(1), page(2)], "a second extend shrinks the range from the same anchor")
        expect(selection.anchor == page(1), "extend keeps the anchor")
    }

    static func extendWithoutAnchorSelectsPage() {
        let selection = selection { $0.extend(to: page(2), in: pages) }
        expect(selection.ids == [page(2)], "extend without an anchor selects only that page")
        expect(selection.anchor == page(2), "extend without an anchor makes that page the anchor")
    }

    static func extendToUnknownPageSelectsIt() {
        let selection = selection {
            $0.select(page(1))
            $0.extend(to: stranger, in: pages)
        }
        expect(selection.ids == [stranger], "extend to a page outside the list selects only that page")
    }

    static func stepMovesToNeighbour() {
        let selection = selection {
            $0.select(page(1))
            $0.step(by: 1, in: pages)
        }
        expect(selection.ids == [page(2)], "step by 1 selects the next page")
        expect(selection.anchor == page(2), "step moves the anchor along")
    }

    static func stepStopsAtLastPage() {
        let selection = selection {
            $0.select(page(3))
            $0.step(by: 10, in: pages)
        }
        expect(selection.ids == [page(4)], "a step past the end stops at the last page")
    }

    static func stepStopsAtFirstPage() {
        let selection = selection {
            $0.select(page(1))
            $0.step(by: -10, in: pages)
        }
        expect(selection.ids == [page(0)], "a step before the start stops at the first page")
    }

    static func stepWithoutAnchorForwardPicksFirstPage() {
        let selection = selection { $0.step(by: 1, in: pages) }
        expect(selection.ids == [page(0)], "a forward step without an anchor selects the first page")
    }

    static func stepWithoutAnchorBackwardPicksLastPage() {
        let selection = selection { $0.step(by: -1, in: pages) }
        expect(selection.ids == [page(4)], "a backward step without an anchor selects the last page")
    }

    static func stepInEmptyListClears() {
        let selection = selection {
            $0.select(page(1))
            $0.step(by: 1, in: [])
        }
        expect(selection.ids.isEmpty && selection.anchor == nil, "a step in an empty page list clears the selection")
    }
}
