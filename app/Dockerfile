FROM node:20-alpine3.23
RUN apk update && apk upgrade

WORKDIR /app

COPY package*.json ./

RUN npm ci

COPY . .

EXPOSE 8080

CMD ["node", "server.js"]
