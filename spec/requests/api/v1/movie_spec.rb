require 'rails_helper'

RSpec.describe "when a search is executed" do
  it 'can return results for search_term' do
    search_term = 'thomas'

    get "/api/v1/movies?s=#{search_term}"

    parsed = JSON.parse(response.body)

    expect(response).to be_successful
    expect(response).to have_http_status(200)

    parsed['Search'].each do |movie|
      assert_equal true, movie['Title'].downcase.include?(search_term), "entry does not match search term (#{search_term})"

      # happy path - has required keys
      required_keys = %w[Title Year imdbID Type Poster]
      movie.all? do |key, value|
        assert_equal true, required_keys.include?(key), "this entry is missing one or more required keys (#{required_keys})"
        assert_equal true, value.is_a?(String), "this value #{value} is not a string"
      end

      # sad path- test will fail if missing a key
      required_keys = %w[Extra_key]
      movie.all? do |key, value|
        assert_equal false, required_keys.include?(key)
        assert_equal true, value.is_a?(String), "this value #{value} is not a string"
      end

      assert_equal false, movie['Year'].nil?
      assert_equal true, Date.strptime(movie['Year'], '%y').gregorian?
      assert_equal true, movie['Year'].to_i.between?(1900, 2999)
    end
  end

  it 'it returns no api key provided without the proper credentials' do
    search_term = 'thomas'

    old_omdb_key = ENV['OMDB_KEY']
    ENV['OMDB_KEY'] = ""

    get "/api/v1/movies?s=#{search_term}"

    expect(response).to have_http_status(200)
    parsed = JSON.parse(response.body)

    assert_equal ('application/json; charset=utf-8'), response.headers['content-type']
    assert_equal 'No API key provided.', parsed['Error']
    assert_equal 'False', parsed['Response']

    # teardown
    ENV['OMDB_KEY'] = old_omdb_key
  end

  it 'test_with_api_key_and_i_value_successful_response' do
    random_imdbid_value = 'tt3896198'
    get "/api/v1/movies?i=#{random_imdbid_value}"

    parsed = JSON.parse(response.body)
    expect(response).to have_http_status(200)

    assert_equal 'application/json; charset=utf-8', response.headers['content-type']
    assert_equal 'True', parsed['Response']
    assert_equal false, parsed['Title'].nil?
  end

  # Sad Path - The api doesn't allow long, short searches.  For example, 't' instead of 'thomas'
  it 'test_search_capability_with_too_short_keyword' do
    search_term = 't'
    get "/api/v1/movies?s=#{search_term}"

    expect(response).to have_http_status(200)
    parsed = JSON.parse(response.body)

    assert_equal 'False', parsed['Response']
    assert_equal 'Too many results.', parsed['Error']
  end

  it 'test_page_one_title_is_valid_using_i_parameter' do
    search_term = 'thomas'
    page_num = 1

    get "/api/v1/movies?s=#{search_term}&page=#{page_num}"
    # request('GET', "?s=#{search_term}&apikey=#{ENV['OMDB_KEY']}&page=#{page_num}", {}, 'http://www.omdbapi.com/')

    expect(response).to have_http_status(200)
    parsed = JSON.parse(response.body)

    searched_movies = parsed['Search']
    searched_movies.each do |movie|
      get "/api/v1/movies?i=#{movie['imdbID']}&apikey=#{ENV['OMDB_KEY']}"

      parsed = JSON.parse(response.body)

      assert_equal 200, response.status
      assert_equal 'True', parsed['Response']
      assert_equal false, parsed['Title'].nil?
    end
  end

  # sad path - check with an intentionally bad imdbID value
  it 'test_page_one_title_is_invalid_using_invalid_i_parameter' do
    wrong_imdbid_value = 11111111111
    get "/api/v1/movies?i=#{wrong_imdbid_value}&apikey=#{ENV['OMDB_KEY']}"

    parsed = JSON.parse(response.body)

    assert_equal 200, response.status
    assert_equal 'False', parsed['Response']
    assert_equal true, parsed['Title'].nil?
  end

  it 'test_all_poster_links_on_page_one_valid' do 
    search_term = 'thomas'
    page_num = 1
    get "/api/v1/movies?s=#{search_term}&apikey=#{ENV['OMDB_KEY']}&page=#{page_num}"

    parsed = JSON.parse(response.body)

    assert_equal 200, response.status
    searched_movies = parsed['Search']

    searched_movies.each do |movie|
      poster_url = movie['Poster']

      poster_request = Faraday.get(poster_url)

      assert_equal 200, poster_request.status

      expect(poster_request.headers['content-type']).to eq("image/jpeg")
    end
  end

  # sad path - check with an intentinally bad url 
  it 'test_reports_poster_link_invalid_with_bad_link' do 
    bad_poster_url = 'https://m.media-amazon.com/images/M/link_to_nowhere.jpg'

    poster_request = Faraday.get(bad_poster_url)

    assert_equal 404, poster_request.status
  end

  it 'test_no_duplicate_records_within_first_n_pages' do 
    search_term = 'thomas'
    page_num = 1
    number_of_pages = 5
    @seen_movie_ids = []

    number_of_pages.times do
      get "/api/v1/movies?s=#{search_term}&apikey=#{ENV['OMDB_KEY']}&page=#{page_num}"

      parsed = JSON.parse(response.body)

      searched_movies = parsed['Search']
      searched_movies.each do |movie|
        assert_equal false, @seen_movie_ids.include?(movie['imdbID']), "There is a duplicate movie with imdbID - #{movie['imdbID']} within page - #{page_num}"
        @seen_movie_ids << movie['imdbID']
      end
      page_num += 1
    end
  end

  # sad path - search contains duplication
  it 'test_duplicate_records_found_within_first_n_pages' do 
    search_term = 'thomas'
    page_num = 1
    number_of_pages = 5
    @seen_movie_ids = []

    number_of_pages.times do
      get "/api/v1/movies?s=#{search_term}&apikey=#{ENV['OMDB_KEY']}&page=#{page_num}"

      parsed = JSON.parse(response.body)
      searched_movies = parsed['Search']

      # force duplication in @seen_movie_ids
      searched_movies.each { |movie| @seen_movie_ids << movie['imdbID'] }

      searched_movies.each do |movie|
        assert_equal true, @seen_movie_ids.include?(movie['imdbID'])
        @seen_movie_ids << movie['imdbID']
      end
    end
  end
end