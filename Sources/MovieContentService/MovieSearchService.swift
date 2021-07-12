import Foundation
import OpenCombine
import OpenCombineDispatch
import OpenCombineFoundation

public class MovieSearchService: OpenCombine.ObservableObject {
    private actor MovieSearchResults {
        weak var searchService: MovieSearchService?
        
        init(searchService: MovieSearchService) {
            self.searchService = searchService
        }
        
        func update(results: [Movie]) throws {
            try Task.checkCancellation()
            guard let service = searchService else {
                return
            }
            service.searchResults += results
        }
        
        func reset() throws {
            try Task.checkCancellation()
            guard let service = searchService else {
                return
            }
            service.searchResults = []
        }
    }
    
    var movieContent: MovieContent
    @OpenCombine.Published public var searchResults: [Movie] = []
    
    private var results: MovieSearchResults!
    private var searchJob: Db2Handler.Job<Movie>?
    private var searchTask: Task.Handle<(), Never>?
    
    public init(movieContent: MovieContent) {
        self.movieContent = movieContent
        results = MovieSearchResults(searchService: self)
    }

    public func attemptHandle(query: String) {
        async {
            do {
                try await self.handle(query: query)
            } catch let error {
                print("Cannot handle query [\(query)]: \(error)")
            }
        }
    }

    public func attemptNextPage(reset: Bool) {
        async {
            do {
                try await self.nextResults(reset: reset)
            } catch let error {
                print("Cannot handle query next page: \(error)")
            }
        }
    }
    
    func handle(query: String) async throws {
        if let searchTask = searchTask {
            searchTask.cancel()
            self.searchTask = nil
        }
        searchJob = nil
        
        if query == "" {
            try await results.reset()
        } else {
            self.searchTask = async {
                do {
                    print(query)
                    let job = try await movieContent.movies(by: query)
                    self.searchJob = job
                    try await self.nextResults(reset: true)
                } catch let error {
                    print("Could not search movies with query \"\(query)\": \(error)")
                }
            }
        }
    }
    
    func nextResults(reset: Bool = false) async throws {
        guard let job = searchJob else {
            return
        }
        guard let movies = try await movieContent.movies(from: job) else {
            return
        }
        if reset {
            try await results.reset()
        }
        try await results.update(results: movies)
    }
}
