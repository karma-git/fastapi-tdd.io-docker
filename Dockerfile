# pull official base image
FROM python:3.10.1-alpine3.14

# set desired poetry version via build-arg
ARG POETRY_VERSION

# set working directory
WORKDIR /usr/src/app

# create non-privileged user and set permission on source directory
RUN addgroup --gid 10001 app \
  && adduser \
    --uid 10001 \
    --home /home/app \
    --shell /bin/ash \
    --ingroup app \
    --disabled-password \
    app \
  && chown -R 10001:10001 /usr/src/app

# set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# copy dependencies info
COPY ./poetry.lock ./
COPY ./pyproject.toml ./

RUN apk add --no-cache \
    jpeg~=9d \
    libxslt-dev~=1.1 \
    py3-psycopg2~=2.8.6 \
  # dependencies for lxml, pillow and poetry
  && apk add --no-cache --virtual .build-deps \
     build-base~=0.5 \
     g++~=10.3 \
     gcc~=10.3 \
     jpeg-dev~=9d \
     libffi-dev~=3.3 \
     libxml2-dev~=2.9 \
     libxml2~=2.9 \
     make~=4.3 \
     musl-dev~=1.2.2 \
     python3-dev~=3.9.5 \
     zlib-dev~=1.2 \
  && pip install --upgrade pip \
  && pip install --no-cache-dir poetry==${POETRY_VERSION} \
  && poetry config virtualenvs.create false \
  && poetry install \
  && apk del .build-deps

# copy project files
COPY ./project ./

USER 10001

EXPOSE 8000

ENTRYPOINT ["/usr/local/bin/uvicorn"]
CMD ["app.main:app", "--reload", "--workers=1",  "--host=0.0.0.0", "--port=8000"]
