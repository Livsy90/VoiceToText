import SwiftUI
import UniformTypeIdentifiers

@MainActor
struct ContentView: View {
    @State private var viewModel: TranscriptionViewModel

    init(viewModel: TranscriptionViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.secondarySystemBackground)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        heroSection
                        actionSection(viewModel: viewModel)
                        contentSection(viewModel: viewModel)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Voice to Text")
        }
        .task {
            viewModel.loadSupportedLanguagesIfNeeded()
        }
        .fileImporter(
            isPresented: $viewModel.isFileImporterPresented,
            allowedContentTypes: [.audio]
        ) { result in
            viewModel.handleImportedFile(result)
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Transcribe audio from Files")
                .font(.system(.largeTitle, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            Text("Import an audio file, wait for recognition, and immediately work with the ready text: review, copy, and share the result.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func actionSection(viewModel: TranscriptionViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Recognition language")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.semibold)

                if viewModel.isLoadingLanguages {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Loading available languages...")
                            .foregroundStyle(.secondary)
                    }
                    .font(.system(.body, design: .rounded))
                } else {
                    Picker("Recognition language", selection: $viewModel.selectedLanguageIdentifier) {
                        ForEach(viewModel.supportedLanguages) { language in
                            Text(language.displayName).tag(language.id)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }

            Button {
                viewModel.openImporter()
            } label: {
                Label("Choose audio file", systemImage: "waveform.badge.plus")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.accentColor)
            .disabled(!viewModel.canImportAudio)

            HStack(spacing: 12) {
                Button {
                    viewModel.copyText()
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.canShareOrCopy)

                ShareLink(item: viewModel.shareText) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(!viewModel.canShareOrCopy)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func contentSection(viewModel: TranscriptionViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            switch viewModel.state {
            case .idle:
                emptyState
            case .processing(let fileName):
                processingState(fileName: fileName)
            case .loaded(let result):
                transcriptionState(
                    title: result.sourceFileName,
                    text: result.text,
                    footnote: "Ready to copy and share."
                )
            case .failed(let message, let lastResult):
                if let lastResult {
                    transcriptionState(
                        title: lastResult.sourceFileName,
                        text: lastResult.text,
                        footnote: message
                    )
                } else {
                    errorState(message: message)
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Transcribed text will appear here", systemImage: "text.quote")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.semibold)

            Text("Import audio using the system picker from the Files app.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func processingState(fileName: String) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            ProgressView()
                .controlSize(.large)

            Text("Transcribing \(fileName)")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.semibold)

            Text("The model processes the file on device and will prepare the final text when finished.")
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func transcriptionState(
        title: String,
        text: String,
        footnote: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.semibold)

            Text(footnote)
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(.secondary)

            Text(text)
                .font(.system(.body, design: .serif))
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func errorState(message: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Transcription failed", systemImage: "exclamationmark.triangle")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.semibold)
                .foregroundStyle(.red)

            Text(message)
                .font(.system(.body, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ContentView(viewModel: AppContainer.live.makeTranscriptionViewModel())
}
