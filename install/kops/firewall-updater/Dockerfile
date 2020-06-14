FROM python:3.8.3 as base
FROM base as builder
RUN apt-get -qq update \
    && apt-get install -y --no-install-recommends \
        g++ \
    && rm -rf /var/lib/apt/lists/*

# Enable unbuffered logging
FROM base as final
ENV PYTHONUNBUFFERED=1

RUN pip install --upgrade google-api-python-client

RUN apt-get -qq update \
    && apt-get install -y --no-install-recommends \
        wget

WORKDIR /helloserver

# Grab packages from builder
COPY --from=builder /usr/local/lib/python3.8/ /usr/local/lib/python3.8/

# Add the application
COPY . .

ENTRYPOINT [ "python", "firewall.py" ]



