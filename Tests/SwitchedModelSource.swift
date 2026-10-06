import Synchronization

// So that a check turns the model on later and sees when a run looked for it.
final class SwitchedModelSource: Sendable {
    private let model: any DocumentLanguageModel
    private let state = Mutex<(isOn: Bool, lookups: Int)>((false, 0))

    init(model: any DocumentLanguageModel) {
        self.model = model
    }

    var lookups: Int { state.withLock { $0.lookups } }

    func turnOn() {
        state.withLock { $0.isOn = true }
    }

    func find() -> (any DocumentLanguageModel)? {
        let isOn = state.withLock { state in
            state.lookups += 1
            return state.isOn
        }
        return isOn ? model : nil
    }
}
