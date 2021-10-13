FROM python:3.8-slim

ENV WEBSITES_PORT 5000
EXPOSE ${WEBSITES_PORT}

RUN mkdir -p /app
WORKDIR /app

COPY Pipfile Pipfile
COPY Pipfile.lock Pipfile.lock
RUN pip install --upgrade pip && pip install pipenv
RUN pipenv install --deploy --system

COPY . /app

CMD ["sh", "-c", "streamlit run --server.port ${WEBSITES_PORT} st_app.py"]