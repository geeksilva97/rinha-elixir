FROM elixir:latest

ARG NODE_NAME
ENV NODE_ENV $NODE_ENV

WORKDIR /app

COPY . .

RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get

RUN mix compile


# CMD ["mix", "run", "--no-halt"]
CMD ["mix", "run", "--no-halt"]
