import Darwin
import Foundation
import UniformTypeIdentifiers

struct ProbeArguments {
    let fileExtension: String
    let bundleID: String
    let restoreBundleID: String?
}

enum ProbeArgumentError: Error {
    case missingValue(String)
    case unknownArgument(String)
}

func parseArguments(_ arguments: [String]) throws -> ProbeArguments {
    var fileExtension: String?
    var bundleID: String?
    var restoreBundleID: String?

    var iterator = arguments.makeIterator()
    while let argument = iterator.next() {
        switch argument {
        case "--extension":
            guard let value = iterator.next() else {
                throw ProbeArgumentError.missingValue(argument)
            }
            fileExtension = value
        case "--bundle-id":
            guard let value = iterator.next() else {
                throw ProbeArgumentError.missingValue(argument)
            }
            bundleID = value
        case "--restore-bundle-id":
            guard let value = iterator.next() else {
                throw ProbeArgumentError.missingValue(argument)
            }
            restoreBundleID = value
        default:
            throw ProbeArgumentError.unknownArgument(argument)
        }
    }

    guard let fileExtension, let bundleID else {
        throw ProbeArgumentError.missingValue("--extension/--bundle-id")
    }

    return ProbeArguments(
        fileExtension: fileExtension,
        bundleID: bundleID,
        restoreBundleID: restoreBundleID
    )
}

func printMachineReadableResult(_ result: AssociationVerificationResult) {
    let effective = result.effectiveBundleID ?? "nil"
    print("requested=\(result.requestedBundleID)")
    print("effective=\(effective)")
    print("status=\(result.status)")
}

do {
    let arguments = try parseArguments(Array(ProcessInfo.processInfo.arguments.dropFirst()))
    guard let contentType = UTType(filenameExtension: arguments.fileExtension) else {
        print("requested=\(arguments.bundleID)")
        print("effective=nil")
        print("status=unsupportedTarget")
        exit(EXIT_SUCCESS)
    }

    let client = LaunchServicesClient()
    let verifier = LaunchServicesAssociationVerifier(client: client)
    let result = verifier.verify(requestedBundleID: arguments.bundleID, for: contentType)

    defer {
        if let restoreBundleID = arguments.restoreBundleID {
            try? client.setDefaultEditor(bundleID: restoreBundleID, for: contentType)
        }
    }

    printMachineReadableResult(result)
} catch {
    fputs("error=\(error)\n", stderr)
    exit(EXIT_FAILURE)
}
