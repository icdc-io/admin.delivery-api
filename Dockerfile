FROM ruby:3.0.2

LABEL author=dmemekh@ibagroup.eu

#RUN apk --no-cache add curl

WORKDIR /usr/src/app

COPY Gemfile ./

RUN bundle install

COPY . .

RUN chgrp -R 0  /usr/src/app && chmod -R g+rwX /usr/src/app

EXPOSE 3000

CMD ["bundle", "exec", "rails", "s", "-b", "0.0.0.0"]