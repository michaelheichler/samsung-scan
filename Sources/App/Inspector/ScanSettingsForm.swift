import SwiftUI

struct ScanSettingsForm: View {
    @Bindable var session: ScanSession
    @Binding var draft: ScanRequest
    let capabilities: ScannerCapabilities

    var body: some View {
        Form {
            Section {
                SourcePicker(sources: capabilities.sources, source: $draft.source)
                if !session.usesFlatbed {
                    PageLimitPicker(pageLimit: $draft.pageLimit)
                }
            }
            Section {
                FormatPicker(session: session, region: draft.region)
                ColorModePicker(modes: capabilities.modes, mode: $draft.mode)
                ResolutionPicker(choices: capabilities.resolutionChoices, resolution: $draft.resolution)
                LabeledContent(
                    "Image Size",
                    value: InspectorFormat.pixels(draft.region.pixelSize(resolution: draft.resolution)))
            }
            let options = capabilities.adjustableExtraOptions
            if !options.isEmpty {
                AdvancedOptionsSection(options: options, draft: $draft)
            }
        }
        .formStyle(.grouped)
        .disabled(session.phase.isBusy)
    }
}
