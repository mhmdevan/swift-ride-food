import Testing
@testable import FeatureFlags

@Test
func refreshUpdatesFeatureFlagsFromProvider() async {
    let provider = MockRemoteConfigProvider(
        values: [
            .enableWebSocket: false,
            .enableNewCatalogUI: true,
            .enableGraphQLOffersBackend: true
        ]
    )
    let service = FeatureFlagsService(remoteConfigProvider: provider)

    let refreshed = await service.refresh()

    #expect(refreshed.enableWebSocket == false)
    #expect(refreshed.enableNewCatalogUI == true)
    #expect(refreshed.enableGraphQLOffersBackend == true)
}

@Test
func refreshKeepsPreviousValuesWhenFetchFails() async {
    let provider = MockRemoteConfigProvider(
        values: [
            .enableWebSocket: true,
            .enableNewCatalogUI: true,
            .enableGraphQLOffersBackend: true
        ]
    )
    let service = FeatureFlagsService(
        remoteConfigProvider: provider,
        initialFlags: FeatureFlags(
            enableWebSocket: false,
            enableNewCatalogUI: false,
            enableGraphQLOffersBackend: false
        )
    )

    await provider.setFetchFailure(true)
    let refreshed = await service.refresh()

    #expect(
        refreshed == FeatureFlags(
            enableWebSocket: false,
            enableNewCatalogUI: false,
            enableGraphQLOffersBackend: false
        )
    )
}

@Test
func refreshReflectsChangedProviderValuesWithoutRebuild() async {
    let provider = MockRemoteConfigProvider(
        values: [
            .enableWebSocket: true,
            .enableNewCatalogUI: false,
            .enableGraphQLOffersBackend: false
        ]
    )
    let service = FeatureFlagsService(remoteConfigProvider: provider)

    _ = await service.refresh()
    await provider.setValue(false, for: .enableWebSocket)
    await provider.setValue(true, for: .enableNewCatalogUI)
    await provider.setValue(true, for: .enableGraphQLOffersBackend)

    let refreshed = await service.refresh()

    #expect(refreshed.enableWebSocket == false)
    #expect(refreshed.enableNewCatalogUI == true)
    #expect(refreshed.enableGraphQLOffersBackend == true)
}
