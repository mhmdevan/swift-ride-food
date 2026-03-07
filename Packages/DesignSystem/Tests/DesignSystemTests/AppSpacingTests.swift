import Testing
@testable import DesignSystem

@Test
func spacingScaleIsAscending() {
    #expect(AppSpacing.small < AppSpacing.medium)
    #expect(AppSpacing.medium < AppSpacing.large)
}
