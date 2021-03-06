import Foundation

public class Session: NSURLSession {

    // MARK: - Properties

    public var outputDirectory: String
    public let cassetteName: String
    public var recordingEnabled = true
    private let testBundle: NSBundle


    // MARK: - Initializers

    public init(outputDirectory: String = "~/Desktop/DVR/", cassetteName: String, testBundle: NSBundle = NSBundle.allBundles().filter() { $0.bundlePath.hasSuffix(".xctest") }.first!) {
        self.outputDirectory = outputDirectory
        self.cassetteName = cassetteName
        self.testBundle = testBundle
        super.init()
    }


    // MARK: - NSURLSession

    public override func dataTaskWithRequest(request: NSURLRequest) -> NSURLSessionDataTask? {
        return SessionDataTask(session: self, request: request)
    }

    public override func dataTaskWithRequest(request: NSURLRequest, completionHandler: (NSData?, NSURLResponse?, NSError?) -> Void) -> NSURLSessionDataTask? {
        return SessionDataTask(session: self, request: request, completion: completionHandler)
    }


    // MARK: - Internal

    var cassette: Cassette? {
        guard let path = testBundle.pathForResource(cassetteName, ofType: "json"), data = NSData(contentsOfFile: path) else { return nil }
        do {
            if let json = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? [String: AnyObject] {
                return Cassette(dictionary: json)
            }
        } catch {}
        return nil
    }
}
