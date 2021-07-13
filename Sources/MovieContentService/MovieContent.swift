import Foundation

public actor MovieContent {
    enum ContentError: Error {
        case noResultsFound
    }
    
    enum RequestError: Error {
        case invalidURL
        case invalidResponse(String)
    }
    
    private var db2Handler: Db2Handler
    private var movies: [Int: Movie] = [:]
    private var genres: [Movie: [String]] = [:]
    private var productionCompanies: [Movie: [String]] = [:]
    
    public init(db2Handler: Db2Handler) {
        self.db2Handler = db2Handler
    }
    
    private func getMovie(id: Int) async throws -> Movie? {
        let response: Db2Handler.QueryResponse<Movie> = try await db2Handler.runSyncJob(service: "GetMovieByID",
                                                                                        version: "1.0",
                                                                                        parameters: ["movieId": id])
        guard response.rowCount == 1 else {
            return nil
        }
        return response.resultSet?[0]
    }
    
    private func getMovie(name: String, limit: Int) async throws -> Db2Handler.Job<Movie> {
        let response: Db2Handler.Job<Movie> = try await db2Handler.runAsyncJob(service: "GetMovieByName", version: "1.0",
                                                                               parameters: ["title": name.lowercased()],
                                                                               limit: limit)
        return response
    }
    
    private func getGenres(id: Int) async throws -> [MovieGenreLink] {
        let response: Db2Handler.QueryResponse<MovieGenreLink> = try await db2Handler.runSyncJob(service: "GetMovieGenres", version: "1.0",
                                                                                                 parameters: ["movieId": id])
        guard let result = response.resultSet else {
            throw ContentError.noResultsFound
        }
        return result
    }
    
    private func getProductionCompanies(id: Int) async throws -> [MovieProductionCompanyLink] {
        let response: Db2Handler.QueryResponse<MovieProductionCompanyLink> = try await db2Handler.runSyncJob(service: "GetMovieProductionCompanies",
                                                                                                             version: "1.0", parameters: ["movieId": id])
        guard let result = response.resultSet else {
            throw ContentError.noResultsFound
        }
        return result
    }

    public func movie(by id: Int) async throws -> Movie {
        if let movie = movies[id] {
            return movie
        }

        guard let movie = try await getMovie(id: id) else {
            throw ContentError.noResultsFound
        }
        movies[id] = movie
        return movie
    }
    
    public func movies(by name: String) async throws -> Db2Handler.Job<Movie> {
        try await getMovie(name: name, limit: 10)
    }
    
    public func movies(from job: Db2Handler.Job<Movie>) async throws -> [Movie]? {
        guard let movies = try await job.nextPage()?.resultSet else {
            return nil
        }
        for movie in movies {
            self.movies[movie.movieID] = movie
        }
        try Task.checkCancellation()
        return movies
    }
    
    public func genres(for movie: Movie) async throws -> [String] {
        if let genres = self.genres[movie] {
            return genres
        }
        
        let genres = try await getGenres(id: movie.movieID).map { $0.name }
        self.genres[movie] = genres
        return genres
    }
    
    public func productionCompanies(for movie: Movie) async throws -> [String] {
        if let productionCompanies = self.productionCompanies[movie] {
            return productionCompanies
        }
        
        let productionCompanies = try await getProductionCompanies(id: movie.movieID).map { $0.name }
        self.productionCompanies[movie] = productionCompanies
        return productionCompanies
    }
}
