# Use node:alpine as the base image
FROM node:alpine

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json to the container
COPY app/package.json app/package-lock.json ./

# Install dependencies
RUN npm install

# Copy the entire project to the container
COPY app .

# Build the React app
RUN npm run build

# Expose port 3000 (change if your app runs on a different port)
EXPOSE 3000

# Start the React app
CMD ["npm", "start"]

