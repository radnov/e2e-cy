FROM 'cypress/included:10.0.3'

ENV CYPRESS_VIDEO=false
WORKDIR /usr/test
RUN apt install -y python3-pip && \
  pip3 install requests
COPY ./package.json ./package.json
RUN npm install
COPY ./merge_launches.py ./merge_launches.py
COPY ./cypress.config.js ./cypress.config.js
COPY ./reporter-config.json ./reporter-config.json
COPY ./cypress ./cypress

CMD ["/bin/sh", "-c", "sleep 15"]