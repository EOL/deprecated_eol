FROM encoflife/ruby
MAINTAINER Dmitry Mozzherin

RUN apt-get update -q && \
    apt-get install -qq -y software-properties-common  nodejs \
      libmysqlclient-dev libqt4-dev && \
    add-apt-repository -y ppa:nginx/stable && \
    apt-get update && \
    apt-get install -qq -y nginx && \
    echo "\ndaemon off;" >> /etc/nginx/nginx.conf && \
    chown -R www-data:www-data /var/lib/nginx && \
    gem install foreman
ADD config/docker/nginx-sites.conf /etc/nginx/sites-enabled/default

WORKDIR /app
ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock
RUN bundle install
ADD . /app

ADD config/docker/Procfile /app/Procfile
ENV RAILS_ENV production

#CMD bundle exec rake assets:precompile && foreman start -f Procfile
