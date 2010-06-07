use Rack::Session::Cookie

run lambda { |env|
  request  = Rack::Request.new env
  response = Rack::Response.new
  params   = request.params
  session  = env['rack.session']
  response.body = case request.path_info

  when '/'
    "You said #{ params['say'] || 'nothing' }"

  when '/print-method'
    request.request_method.downcase

  when '/print-session'
    session['session_variable'] = params['session_variable'] if params['session_variable']
    session['session_variable']

  when '/redirect'
    response.headers['Location'] = params['to']
    response.status = 302 # manually set!
    ''

  when '/relative'
    response.headers['Location'] = '/i_am_relative'
    response.status = 302 # manually set!
    ''

  when '/some_text'
    "hello there, how goes it?"

  when '/some_html'
    %q{
      <html>
        <head></head>
        <body>
          <p id="this-one"></p>
          <p id="bacon-one"></p>
          <div id="chunky-one">
            <b>chunky one</b>
            <div></div>
          </div>
        </body>
      </html>
    }

  else
    "DON'T KNOW HOWTO RESPOND TO PATH: #{ request.path_info }"

  end.to_s
  response.finish
}
