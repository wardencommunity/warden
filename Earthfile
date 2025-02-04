VERSION 0.7

# This allows one to change the running Ruby version with:
#
# `earthly --allow-privileged +rspec --EARTHLY_RUBY_VERSION=2.5`
ARG --global EARTHLY_RUBY_VERSION=3.3
# This allows one to change the imported Gemfile from the `gemfiles` folder:
#
# `earthly --allow-privileged +rspec --EARTHLY_RACK_VERSION=2`
ARG --global EARTHLY_RACK_VERSION=3
# Of course you can mix both!

FROM ruby:$EARTHLY_RUBY_VERSION
WORKDIR /gem

deps:
    COPY gemfiles/rack_$EARTHLY_RACK_VERSION.gemfile /gem/Gemfile
    COPY *.gemspec /gem
    COPY lib/warden/version.rb /gem/lib/warden/version.rb

    RUN apt update \
        && apt install --yes \
                       --no-install-recommends \
                       build-essential \
                       git \
        && sed -i 's/path: "\.\.\/"//g' /gem/Gemfile \
        && bundle install --jobs $(nproc)

    SAVE ARTIFACT /usr/local/bundle bundler
    SAVE ARTIFACT /gem/Gemfile Gemfile
    SAVE ARTIFACT /gem/Gemfile.lock Gemfile.lock

dev:
    RUN apt update \
        && apt install --yes \
                       --no-install-recommends \
                       git

    COPY +deps/bundler /usr/local/bundle
    COPY +deps/Gemfile /gem/Gemfile
    COPY +deps/Gemfile.lock /gem/Gemfile.lock

    COPY *.gemspec /gem
    COPY Rakefile /gem

    COPY lib/ /gem/lib/
    COPY spec/ /gem/spec/
    COPY .rspec /gem/

    ENTRYPOINT ["bundle", "exec"]
    CMD ["rake"]

    SAVE IMAGE wardencommunity/warden:latest

#
# This target runs the test suite.
#
# Use the following command in order to run the tests suite:
# earthly --allow-privileged +rspec
#
# See the above `EARTHLY_RUBY_VERSION` and `EARTHLY_RACK_VERSION` arguments.
rspec:
    FROM earthly/dind:alpine

    COPY docker-compose.yml ./

    WITH DOCKER --load wardencommunity/warden:latest=+dev
        RUN docker-compose run --rm gem
    END
