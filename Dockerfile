FROM elixir:latest

ARG NODE_NAME
ENV NODE_NAME $NODE_NAME

RUN echo $NODE_ENV

WORKDIR /app

COPY . .

RUN mix local.hex --force && \
    mix local.rebar --force && \
    mix deps.get

RUN mix compile


# CMD ["elixir", "--sname", "diogenes", "-S", "mix", "run", "--no-halt"]
CMD elixir --sname $NODE_NAME -S mix run --no-halt
