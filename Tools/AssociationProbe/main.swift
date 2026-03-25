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
    print("requested=\(result.requestedBundleID)")
    print("status=\(result.status)")
    print("effective=\(result.effectiveBundleID ?? "nil")")

    for role in PreferredHandlerRole.verificationOrder {
        let roleResult = result.roleResults.first { $0.preferredHandler.role == role }
        print("\(role.rawValue)_requested=\(result.requestedBundleID)")
        print("\(role.rawValue)_effective=\(roleResult?.preferredHandler.effectiveBundleID ?? "nil")")
        print("\(role.rawValue)_status=\(roleResult?.status.rawValue ?? "nil")")
    }
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
            for role in PreferredHandlerRole.verificationOrder {
                try? client.setDefaultHandler(bundleID: restoreBundleID, for: contentType, role: role)
            }
        }
    }

    printMachineReadableResult(result)
} catch {
    fputs("error=\(error)\n", stderr)
    exit(EXIT_FAILURE)
}
