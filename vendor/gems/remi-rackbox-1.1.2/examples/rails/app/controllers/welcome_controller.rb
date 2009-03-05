class WelcomeController < ApplicationController

  def index
    render :text => "You said #{ params[:say] || 'nothing' }"
  end

  def print_method
    render :text => request.method
  end

  def print_session
    session[:session_variable] = params[:session_variable] if params[:session_variable]
    render :text => session[:session_variable].to_s
  end

  def redirect
    redirect_to params[:to]
  end

  def some_text
    render :text => "well hello there \n how goes it? \n does it go well?"
  end

  def some_html
    # render template
  end

  def relative
    redirect_to '/i_am_relative'
  end

end
