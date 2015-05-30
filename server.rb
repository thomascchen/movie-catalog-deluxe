require 'sinatra'
require 'pg'
require 'pry'

def db_connection
  begin
    connection = PG.connect(dbname: "movies")
    yield(connection)
  ensure
    connection.close
  end
end

def actors
  db_connection { |conn| conn.exec("SELECT id, name FROM actors ORDER BY name")}
end

def actor
  db_connection { |conn| conn.exec("SELECT name FROM actors WHERE id = $1", [params[:id]]) }
end

def actor_info
  db_connection do |conn|
    conn.exec("SELECT actors.name AS actor, movies.id AS movie_id, movies.title AS movie, cast_members.character AS role
    FROM cast_members
    JOIN movies ON cast_members.movie_id = movies.id
    JOIN actors ON cast_members.actor_id = actors.id
    WHERE actors.id = $1", [params[:id]])
  end
end

def movies
  db_connection do |conn|
    conn.exec("SELECT movies.id AS id, movies.title AS movie, movies.year AS year, movies.rating AS rating, genres.name AS genre, studios.name AS studio
    FROM movies
    LEFT JOIN genres ON movies.genre_id = genres.id
    LEFT JOIN studios ON movies.studio_id = studios.id
    ORDER BY movies.title")
  end
end

def movie
  db_connection { |conn| conn.exec("SELECT id, title FROM movies WHERE id = $1", [params[:id]]) }
end

def movie_info
  db_connection { |conn| conn.exec("SELECT movies.title AS movie, movies.year AS year, movies.rating AS rating, genres.name AS genre, studios.name AS studio, actors.id AS actor_id, actors.name AS actor, cast_members.character AS role, movies.synopsis AS synopsis
    FROM movies
    LEFT JOIN cast_members ON movies.id = cast_members.movie_id
    LEFT JOIN genres ON movies.genre_id = genres.id
    LEFT JOIN studios ON movies.studio_id = studios.id
    LEFT JOIN actors ON cast_members.actor_id = actors.id
    WHERE movies.id = $1", [params[:id]]) }
end


get '/' do
  redirect '/movies'
end

get '/actors' do
  erb :'actors/index', locals: { actors: actors }
end

get '/actors/:id' do
  erb :'actors/show', locals: { actor: actor, actor_info: actor_info }
end

get '/movies' do
  erb :'movies/index', locals: { movies: movies }
end

get '/movies/:id' do
  erb :'movies/show', locals: { movie: movie, movie_info: movie_info }
end
