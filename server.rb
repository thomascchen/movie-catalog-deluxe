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
  db_connection do |conn|
    conn.exec("SELECT name FROM actors WHERE id = $1", [params[:id]])
  end
end

def actor_info
  db_connection do |conn|
    conn.exec("SELECT actors.name AS actor, movies.id AS movie_id,
      movies.title AS title, cast_members.character AS role
      FROM cast_members
      JOIN movies ON cast_members.movie_id = movies.id
      JOIN actors ON cast_members.actor_id = actors.id
      WHERE actors.id = $1", [params[:id]])
  end
end

def movies_sort(option)
  sql = "SELECT movies.id AS id, movies.title AS title,
    movies.year AS year, movies.rating AS rating,
    genres.name AS genre, studios.name AS studio
    FROM movies
    LEFT JOIN genres ON movies.genre_id = genres.id
    LEFT JOIN studios ON movies.studio_id = studios.id
    ORDER BY #{option}"

  db_connection do |conn|
    conn.exec_params(sql)
  end
end

def movie
  db_connection do |conn|
    conn.exec("SELECT id, title FROM movies WHERE id = $1", [params[:id]])
  end
end

def movie_info
  db_connection do |conn|
    conn.exec("SELECT movies.title AS title,
      movies.year AS year, movies.rating AS rating, genres.name AS genre,
      studios.name AS studio, actors.id AS actor_id, actors.name AS actor,
      cast_members.character AS role, movies.synopsis AS synopsis
      FROM movies
      LEFT JOIN cast_members ON movies.id = cast_members.movie_id
      LEFT JOIN genres ON movies.genre_id = genres.id
      LEFT JOIN studios ON movies.studio_id = studios.id
      LEFT JOIN actors ON cast_members.actor_id = actors.id
      WHERE movies.id = $1", [params[:id]])
  end
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
  if params[:order] == nil
    params[:order] = 'title'
    movies = movies_sort(params[:order])
  else
    movies = movies_sort(params[:order])
  end

  erb :'movies/index', locals: { movies: movies }
end

get '/movies/:id' do
  erb :'movies/show', locals: { movie: movie, movie_info: movie_info }
end
