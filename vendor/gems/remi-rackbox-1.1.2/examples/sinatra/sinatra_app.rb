get '/' do
  "You said #{ params[:say] || 'nothing' }"
end
post '/' do
  "You said #{ params[:say] || 'nothing' }"
end

# can i roll these into 1?
get '/print-method' do
  request.request_method.downcase
end
put '/print-method' do
  request.request_method.downcase
end
post '/print-method' do
  request.request_method.downcase
end

get '/print-session' do
  session[:session_variable] = params[:session_variable] if params[:session_variable]
  session[:session_variable].to_s
end
post '/print-session' do
  session[:session_variable] = params[:session_variable] if params[:session_variable]
  session[:session_variable].to_s
end

get '/redirect' do
  redirect params[:to]
end

get '/relative' do
  redirect '/i_am_relative'
end

get '/some_text' do
  'hello there, how goes it?'
end

get '/some_html' do
  haml :some_html
end

use_in_file_templates! 

__END__

@@ layout
%html
  %body
    = yield

@@ some_html
%p#this-one
%p#bacon-one
#chunky-one
  %b chunky one
  %div
