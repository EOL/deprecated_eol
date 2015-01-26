FROM encoflife/ruby
MAINTAINER Dmitry Mozzherin

RUN apt-get update -q && \
    apt-get install -qq -y software-properties-common nodejs \
      libmysqlclient-dev libqt4-dev supervisor && \
    add-apt-repository -y ppa:nginx/stable && \
    apt-get update && \
    apt-get install -qq -y nginx && \
    echo "\ndaemon off;" >> /etc/nginx/nginx.conf && \
    chown -R www-data:www-data /var/lib/nginx
COPY config/docker/nginx-sites.conf /etc/nginx/sites-enabled/default

WORKDIR /app
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
RUN bundle install
COPY . /app

COPY config/docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

CMD bundle exec rake assets:precompile && /usr/bin/supervisord
