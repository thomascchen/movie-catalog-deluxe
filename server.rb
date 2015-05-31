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

def actors_page(page, order)
  if page.to_i > 0
    offset = (page.to_i - 1) * 20
  else
    offset = 0
  end

  sql = "SELECT id, name FROM actors ORDER BY name LIMIT 20 OFFSET #{offset}"

  db_connection { |conn| conn.exec(sql)}
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

def movies_page(page, order)
  if page.to_i > 0
    offset = (page.to_i - 1) * 20
  else
    offset = 0
  end

  sql = "SELECT movies.id AS id, movies.title AS title,
    movies.year AS year, movies.rating AS rating,
    genres.name AS genre, studios.name AS studio
    FROM movies
    LEFT JOIN genres ON movies.genre_id = genres.id
    LEFT JOIN studios ON movies.studio_id = studios.id
    ORDER BY #{order} LIMIT 20 OFFSET #{offset}"

  db_connection { |conn| conn.exec(sql) }
end

def movies_search(query)
  sql = "SELECT movies.id AS id, movies.title AS title, movies.year AS year,
    movies.rating AS rating, genres.name AS genre, studios.name AS studio
    FROM movies
    LEFT JOIN genres ON movies.genre_id = genres.id
    LEFT JOIN studios ON movies.studio_id = studios.id
    WHERE title ILIKE '%#{query}%' OR synopsis ILIKE '%#{query}%'"

  db_connection { |conn| conn.exec(sql) }
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
  if params[:order] == nil
    order = 'title'
  else
    order = params[:order]
  end

  if params[:page] == nil
    page = 1
  else
    page = params[:page]
  end

  actors = actors_page(page, order)

  erb :'actors/index', locals: { actors: actors, page: page, order: order }
end

get '/actors/:id' do
  erb :'actors/show', locals: { actor: actor, actor_info: actor_info }
end

get '/movies' do

  if params[:order] == nil
    order = 'title'
  else
    order = params[:order]
  end

  if params[:page] == nil
    page = 1
  else
    page = params[:page]
  end

  movies = movies_page(page, order)

  query = params[:query]

  if query != nil
    movies = movies_search(query)
  end

  erb :'movies/index', locals: { movies: movies, page: page, order: order }
end

get '/movies/:id' do
  erb :'movies/show', locals: { movie: movie, movie_info: movie_info }
end
