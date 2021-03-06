import Foundation

class SessionDataTask: NSURLSessionDataTask {

    // MARK: - Properties

    weak var session: Session!
    let request: NSURLRequest
    let completion: ((NSData?, NSURLResponse?, NSError?) -> Void)?


    // MARK: - Initializers

    init(session: Session, request: NSURLRequest, completion: ((NSData?, NSURLResponse?, NSError?) -> Void)? = nil) {
        self.session = session
        self.request = request
        self.completion = completion
    }


    // MARK: - NSURLSessionDataTask

    override func resume() {
        let cassette = session.cassette

        // Find interaction
        if let interaction = cassette?.interactionForRequest(request) {
            // Forward completion
            completion?(interaction.responseData, interaction.response, nil)
            return
        }

		if cassette != nil {
			fatalError("[DVR] Invalid request. The request was not found in the cassette.")
		}

        // Cassette is missing. Record.
		if session.recordingEnabled == false {
			fatalError("[DVR] Recording is disabled.")
		}

        // Create directory
        let outputDirectory = session.outputDirectory.stringByExpandingTildeInPath
        let fileManager = NSFileManager.defaultManager()
        if !fileManager.fileExistsAtPath(outputDirectory) {
            try! fileManager.createDirectoryAtPath(outputDirectory, withIntermediateDirectories: true, attributes: nil)
        }

        print("[DVR] Recording '\(session.cassetteName)'")

        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) { data, response, error in
            // Create cassette
            let interaction = Interaction(request: self.request, response: response!, responseData: data)
            let cassette = Cassette(name: self.session.cassetteName, interactions: [interaction])

            // Persist
            do {
                let outputPath = outputDirectory.stringByAppendingPathComponent(self.session.cassetteName).stringByAppendingPathExtension("json")!
                let data = try NSJSONSerialization.dataWithJSONObject(cassette.dictionary, options: [.PrettyPrinted])
                data.writeToFile(outputPath, atomically: true)
                fatalError("[DVR] Persisted cassette at \(outputPath). Please add this file to your test target")
            } catch {
                // Do nothing
            }

			fatalError("[DVR] Failed to persist cassette.")
        }
        task?.resume()
    }
}
