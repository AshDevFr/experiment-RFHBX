FROM mcr.microsoft.com/playwright:v1.50.0-noble

WORKDIR /e2e

COPY package.json package-lock.json* ./
RUN npm install

COPY . .
RUN chmod +x wait-for-services.sh

ENTRYPOINT ["./wait-for-services.sh"]
CMD ["npx", "playwright", "test"]
