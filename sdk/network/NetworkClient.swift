import Foundation

enum NetworkError: Error {
    case httpError(Int, String)
    case invalidResponse
}

class NetworkClient {
    private let session: URLSession

    init(timeoutSeconds: TimeInterval) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest  = timeoutSeconds
        config.timeoutIntervalForResource = timeoutSeconds
        session = URLSession(configuration: config)
    }

    func post(
        url: String,
        jsonBody: [String: Any],
        completion: @escaping (Result<Data, NetworkError>) -> Void
    ) {
        guard let requestUrl = URL(string: url) else {
            completion(.failure(.invalidResponse))
            return
        }
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        guard let body = try? JSONSerialization.data(withJSONObject: jsonBody) else {
            completion(.failure(.invalidResponse))
            return
        }
        request.httpBody = body

        session.dataTask(with: request) { data, response, error in
            if error != nil {
                completion(.failure(.invalidResponse))
                return
            }
            guard let http = response as? HTTPURLResponse else {
                completion(.failure(.invalidResponse))
                return
            }
            if http.statusCode != 200 && http.statusCode != 201 {
                let body = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                completion(.failure(.httpError(http.statusCode, body)))
                return
            }
            completion(.success(data ?? Data()))
        }.resume()
    }
}
