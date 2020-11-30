class MoviesSerializer
  include JSONAPI::Serializer
  attributes :imdb_id, :title
end
