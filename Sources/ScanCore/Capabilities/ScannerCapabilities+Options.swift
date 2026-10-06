extension ScannerCapabilities {
    // So that buttons and free text fields, which need no setting, stay hidden.
    public var adjustableExtraOptions: [ScannerOption] {
        extraOptions.filter { option in
            if option.isInactive { return false }
            if case .unconstrained = option.value { return false }
            return true
        }
    }

    // Because scanimage reports the options for the mode it was queried with.
    public func describes(mode: String) -> Bool {
        modes.isEmpty || defaultMode == mode
    }
}
