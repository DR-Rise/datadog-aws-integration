# Use a Node.js base image
FROM node:16

# Set environment variables for Datadog
ENV DD_TRACE_AGENT_URL=http://datadog:8126
ENV DD_SERVICE=my-nodejs-service
ENV DD_ENV=production
ENV DD_VERSION=1.0.0

# Set the working directory
WORKDIR /usr/src/app

# Copy package.json and package-lock.json files
COPY package*.json ./

# Install dependencies
RUN npm install --production

# Copy the application code
COPY . .

# Expose the application port
EXPOSE 3000

# Run the application
CMD ["node", "server.js"]
