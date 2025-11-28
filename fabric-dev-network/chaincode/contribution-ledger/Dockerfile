FROM node:18-alpine

WORKDIR /usr/src/app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy chaincode source
COPY src/ ./src/

# Expose chaincode server port
ARG CC_SERVER_PORT=9999
ENV CHAINCODE_SERVER_ADDRESS=0.0.0.0:${CC_SERVER_PORT}

# Start chaincode server in CaaS mode
CMD ["sh", "-c", "node_modules/.bin/fabric-chaincode-node server --chaincode-address=${CHAINCODE_SERVER_ADDRESS} --chaincode-id=${CHAINCODE_ID}"]

