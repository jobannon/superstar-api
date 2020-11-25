class MovieInfo

  def initialize(incoming)
    @query_params = incoming.to_query
  end

  def get_search_results
    get_json
  end

  private

  def get_json
    response = Faraday.get("http://www.omdbapi.com?#{@query_params}&apikey=#{ENV['OMDB_KEY']}")
    JSON.parse(response.body)
  end

end