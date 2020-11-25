class Api::V1::MoviesController < ApplicationController
  def index

    render json: MovieInfo.new(movie_params).get_search_results
  end

  private

  def movie_params
    params.permit(:s, :i, :page, :apikey)
  end
end