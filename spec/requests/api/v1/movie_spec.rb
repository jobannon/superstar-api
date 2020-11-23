require 'rails_helper'

RSpec.describe "when a search is executed" do
  it 'can return results for search_term' do
    search_term = 'thomas'
    get "/api/v1/movies?search_term=#{search_term}"

    parsed = JSON.parse(response.body)

    expect(response).to be_successful
    expect(response).to have_http_status(200)
    parsed['Search'].each do |movie|
      assert_equal true, movie['Title'].downcase.include?(search_term), "Entry does not match search term (#{search_term})"

      # happy path - has required keys
      required_keys = %w[Title Year imdbID Type Poster]
      movie.all? do |key, value|
        assert_equal true, required_keys.include?(key), "This entry is missing one or more required keys (#{required_keys})"
        assert_equal true, value.is_a?(String), "This value #{value} is not a String"
      end

      # sad path- test will fail if missing a key
      required_keys = %w[Extra_key]
      movie.all? do |key, value|
        assert_equal false, required_keys.include?(key)
        assert_equal true, value.is_a?(String), "This value #{value} is not a String"
      end

      assert_equal false, movie['Year'].nil?
      assert_equal true, Date.strptime(movie['Year'], '%Y').gregorian?
      assert_equal true, movie['Year'].to_i.between?(1900, 2999)
    end
  end
end
