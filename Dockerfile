FROM node:12

LABEL "com.github.actions.name"="Deploy okonni website on AWS"
LABEL "com.github.actions.description"="Builds static html files from Handlebars templates using npm, syncs dist folder to an AWS S3 bucket, invalidates an AWS CloudFront distribution, deploys Lambda functions using Serverless"
LABEL "com.github.actions.icon"="upload-cloud"
LABEL "com.github.actions.color"="green"

LABEL version="1.0.0"
LABEL repository="https://github.com/okonni/aws-deploy-action"
LABEL homepage="https://okonni.com/"
LABEL maintainer="Mircea Preotu <mircea@incognicode.com>"

RUN apt-get update && apt-get install -y zip && rm -rf /var/lib/apt/lists/*
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip
RUN ./aws/install && aws --version

RUN npm install -g hbs-cli serverless

ENV PATH /github/workspace/node_modules/.bin:$PATH
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["node"]
ENTRYPOINT ["/entrypoint.sh"]