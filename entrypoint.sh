#!/bin/bash

set -e

echo "[INFO] Verifying dependencies"

if [ -z "$AWS_ACCESS_KEY_ID" ]; then
  echo "[ERROR] AWS_ACCESS_KEY_ID is missing"
  exit 1
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
  echo "[ERROR] AWS_SECRET_ACCESS_KEY is missing"
  exit 1
fi

if [ -z "$AWS_REGION" ]; then
  echo "[ERROR] AWS_REGION is missing"
  exit 1
fi

if [ -z "$AWS_S3_BUCKET" ]; then
  echo "[ERROR] AWS_S3_BUCKET is missing"
  exit 1
fi


echo "[INFO] Buiding distribution files"

WORKDIR=`pwd`

FILES=`find $WORKDIR | egrep '\.hbs$'`

for file in $FILES; do
  dest="${file//$WORKDIR/}"
   dest="${dest//index.hbs/}"
   dest=$WORKDIR/dist$dest
  echo "[INFO] > source=$file | target=$dest"

  hbs $file --partial "$WORKDIR/partials/*.hbs" --output $dest
done 


echo "[INFO] Preparing aws deployment environment profile"

aws configure --profile aws-deploy-action <<-EOF > /dev/null 2>&1
${AWS_ACCESS_KEY_ID}
${AWS_SECRET_ACCESS_KEY}
${AWS_REGION}
text
EOF


echo "[INFO] Deploying files from dist to S3 ${AWS_S3_BUCKET}/${AWS_S3_BUCKET_FOLDER}"

sh -c "npm install" \
&& sh -c "npm run build" \
&& sh -c "aws s3 sync dist s3://${AWS_S3_BUCKET}/${AWS_S3_BUCKET_FOLDER} \
              --profile aws-deploy-action \
              --no-progress \
              --delete"
SUCCESS=$?

if [ $SUCCESS -eq 0 ]
then
  if [ -n "$AWS_CLOUDFRONT_DISTRIBUTION_ID" ]; then
    echo "[INFO] Invalidating Cloudfront distribution (ID=$AWS_CLOUDFRONT_DISTRIBUTION_ID)"
    sh -c "aws cloudfront create-invalidation \
                          --distribution-id ${AWS_CLOUDFRONT_DISTRIBUTION_ID} \
                          --paths /\*"
  fi
fi

if [ $SUCCESS -eq 0 ]
then
  if [ -d "$WORKDIR/lambda" ]; then
    echo "[INFO] Deploying AWS Lambda functions via Serverless framework"
    sh -c "cd $WORKDIR/lambda && npm install && SLS_DEBUG=1 serverless deploy"
  fi
fi


echo "[INFO] Cleaning up aws deployment environment profile"
aws configure --profile aws-deploy-action <<-EOF > /dev/null 2>&1
null
null
null
text
EOF


if [ $SUCCESS -eq 0 ]
then
  echo "[INFO] Deployment completed successfully"
else
  echo "[INFO] Deployment failed"
  exit 1
fi