FROM python:3.8-slim

ENV PORT 5000
EXPOSE ${PORT}

RUN mkdir -p /app
WORKDIR /app

COPY Pipfile Pipfile
COPY Pipfile.lock Pipfile.lock
RUN pip install --upgrade pip && pip install pipenv
RUN pipenv install --deploy --system

COPY . /app

CMD ["sh", "-c", "streamlit run --server.address 0.0.0.0 --server.port ${PORT} --server.headless true st_app.py"]