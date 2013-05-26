require 'coderay'
require 'haml'
require 'kramdown'
require 'less'
require 'builder'
require 'sinatra/base'
require './lib/coderay/scanners/csharp'
require './lib/coderay/scanners/scala'
require './lib/haml/filters/kramdown'
require './lib/kramdown/document'

class MySite < Sinatra::Base
  set :haml, format: :html5, ugly: true

  RFC822_DATE_FORMAT = '%a, %d %b %Y %H:%M:%S GMT'
  
  # ------------------------------------------------------------------------------

  error 404 do
    haml :error, locals: { title: 'Page not found', message: "Sorry, that page doesn't exist." }
  end

  error 500 do
    haml :error, locals: { title: 'Oops... Something bad happened', message: "Sorry, an error occurred :-(" }
  end

  get '/css/:style.css' do
    filename = params[:style] + '.css'
    if File.exist?(filename)
      send_file File.expand_path(filename, settings.public_folder)
    else
      less params[:style].to_sym
    end
  end

  get '/' do
    redirect '/blog'
  end

  get '/about' do
    haml :about, locals: { area: 'About', title: 'About' }
  end

  get '/blog' do 
    haml :'blog/index', locals: { area: 'Blog', title: 'Blog', posts: blog_posts }
  end

  get '/contact' do
    haml :contact, locals: { area: 'Contact', title: 'Contact Me' }
  end

  get '/blog/rss' do
    content_type 'application/rss+xml'
    posts = blog_posts(include_text: true)
    builder do |rss|
      rss.rss version: '2.0' do
        rss.channel do
          rss.title 'Greg Beech\'s Blog'
          rss.link "http://#{request.host_with_port}/blog"
          rss.description 'Greg Beech\'s Blog'
          rss.language 'en-GB'
          rss.category 'Technology'
          rss.copyright "Copyright (C) Greg Beech 2006-#{Date::today.year}. All Rights Reserved."
          rss.pubDate posts.first[:date].strftime(RFC822_DATE_FORMAT)
          rss.lastBuildDate Time.new.strftime(RFC822_DATE_FORMAT)
          rss.docs 'http://blogs.law.harvard.edu/tech/rss'
          rss.generator 'Greg Beech\'s Website'
          rss.managingEditor 'greg@gregbeech.com'
          rss.webMaster 'greg@gregbeech.com'
          rss.ttl '60'
          posts.each do |post|
            rss.item do
              link = "http://#{request.host_with_port}#{post[:link]}"
              rss.title post[:title]
              rss.link link
              rss.description post[:text]
              rss.pubDate post[:date].strftime(RFC822_DATE_FORMAT)
              rss.guid link
            end
          end
        end
      end
    end
  end

  get '/blog/:key' do
    filename = Dir.glob("blog/**/#{params[:key]}.markdown").first
    halt 404 unless filename
    haml :'blog/post', locals: blog_post(filename).merge({ area: 'Blog' })
  end

  get '/cv' do
    haml :cv, locals: { area: 'CV', title: 'CV' }
  end

  # ------------------------------------------------------------------------------

  def blog_posts(include_text = false)
    posts = Dir.glob('blog/**/*.markdown').map { |filename| blog_post(filename, include_text) }
    posts.reject! { |post| !post[:date] || post[:date] > Date.today } # only show posts with valid date
    posts.sort! { |a, b| b[:date] <=> a[:date] }
  end

  def blog_post(filename, include_text = true)
    document = Kramdown::Document.new(File.read(filename), coderay_line_numbers: nil, coderay_css: :class)
    if include_text
      metadata = document.extract_metadata!
      metadata[:text] = document.to_html
    else 
      metadata = document.metadata
    end
    metadata.merge({ link: '/blog/' + File.basename(filename, '.*') })
  end
  
end