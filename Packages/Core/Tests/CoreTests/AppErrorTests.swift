import Testing
@testable import Core

@Test
func unknownErrorHasFallbackMessage() {
    #expect(AppError.unknown.errorDescription == "Something went wrong. Please try again.")
}

@Test
func validationMessageIsExposedAsDescription() {
    let error = AppError.validation(message: "Email is invalid")
    #expect(error.errorDescription == "Email is invalid")
}
