class Api::V1::MoviesController < ApplicationController
  def index
    render json: MovieInfo.new(movie_params[:search_term]).get_search_results
  end

  private

  def movie_params
    params.permit(:search_term)
  end
end