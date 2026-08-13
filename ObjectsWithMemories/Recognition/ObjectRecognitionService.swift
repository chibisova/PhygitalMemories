protocol ObjectRecognitionService {
    func start()
    func stop()
    var recognitionEvents: AsyncStream<RecognitionEvent> { get }
}
