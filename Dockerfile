FROM node:12

LABEL "com.github.actions.name"="AWS Deploy Action"
LABEL "com.github.actions.description"="Build distribution using npm, syncs dist folder to an AWS S3 bucket and invalidates a AWS CloudFront distribution."
LABEL "com.github.actions.icon"="upload-cloud"
LABEL "com.github.actions.color"="green"

LABEL version="1.0.0"
LABEL repository="https://github.com/mirceapreotu/aws-deploy-action"
LABEL homepage="https://mirceapreotu.com/"
LABEL maintainer="Mircea Preotu <mircea@incognicode.com>"

RUN apt-get update && apt-get install -y zip && rm -rf /var/lib/apt/lists/*
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && unzip awscliv2.zip
RUN ./aws/install && aws --version

ENV PATH /github/workspace/node_modules/.bin:$PATH
ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

CMD ["node"]
ENTRYPOINT ["/entrypoint.sh"]