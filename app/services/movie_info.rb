class MovieInfo

  def initialize(search_term)
    @search_term = search_term
  end

  def get_search_results
    get_json
  end

  private

  def get_json
    response = Faraday.get("http://www.omdbapi.com?s=#{@search_term}&apikey=#{ENV['OMDB_KEY']}")
    JSON.parse(response.body)
  end

end