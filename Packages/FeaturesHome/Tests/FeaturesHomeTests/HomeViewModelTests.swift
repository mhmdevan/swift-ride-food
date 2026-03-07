import Testing
@testable import FeaturesHome

@MainActor
@Test
func queryFiltersActions() {
    let viewModel = HomeViewModel(actions: [.auth, .map, .orders])

    viewModel.query = "map"

    #expect(viewModel.actions == [.map])
}

@MainActor
@Test
func emptyQueryRestoresAllActions() {
    let viewModel = HomeViewModel(actions: [.auth, .map, .orders])

    viewModel.query = "auth"
    viewModel.query = ""

    #expect(viewModel.actions == [.auth, .map, .orders])
}

@MainActor
@Test
func updateActionsReplacesVisibleActionsWhenQueryIsEmpty() {
    let viewModel = HomeViewModel(actions: [.auth, .map, .orders])

    viewModel.updateActions([.auth, .catalog])

    #expect(viewModel.actions == [.auth, .catalog])
}

@MainActor
@Test
func updateActionsReappliesCurrentFilter() {
    let viewModel = HomeViewModel(actions: [.auth, .map, .orders, .catalog])
    viewModel.query = "map"

    viewModel.updateActions([.auth, .catalog])

    #expect(viewModel.actions.isEmpty)
}
