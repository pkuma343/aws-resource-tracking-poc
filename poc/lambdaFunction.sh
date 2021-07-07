#!/bin/sh
# aws configure

export TRUST_POLICY_FILE="file://policies/trustPolicy.json"
export IAM_POLICY_FILE="file://policies/policies.json"
export ZIP_FILE="fileb://poc.zip"


echo "**************************IAM_Role************************"
aws iam get-role --role-name $1 > /dev/null 2>&1
if [ 0 -eq $? ]; then
echo "IAM Role '$1' already exists"
else
echo "IAM Role '$1' Creating...."
      role_arn=`aws iam create-role --role-name "$1" --assume-role-policy-document ${TRUST_POLICY_FILE} --query 'Role.Arn' --output text`
      aws iam put-role-policy --role-name "$1" --policy-name Permissions-Policy-For-Lambda --policy-document ${IAM_POLICY_FILE} 
      sleep 5
      echo "IAM Role: " ${role_arn} "Created Successfully"
fi

read -p "Please Enter a Region: " Region
echo "$Region"

sleep 2

echo "**************************Lambda_Function************************"
aws lambda get-function --function-name "$2" --region $Region > /dev/null 2>&1
if [ 0 -eq $? ]; then
      echo "Lambda Function '$2' already exists"
else
      echo "Lambda '$2' creating....."
      read -p "Enter Source Email_Id: "  fromMail
      echo "send mail from $fromMail!"

      answer="y"
      ARRAY=()
      while [ "$answer" != "${answer#[Yy]}" ];
      do
            read -p "Enter recipient's Email_Id: "  toMail
            ARRAY+=($toMail)
            read -p "Do you wish to add more recipient's address? (y/n)" answer
      done
      echo ${ARRAY[*]}

      read -p "File FORMAT(File_Name.csv) Enter File_Name: " file 
      echo "FileName $file"

      function_arn=`aws lambda create-function --function-name "$2"  --runtime python3.8 --zip-file ${ZIP_FILE} --handler lambda_handler.lambda_handler --role $role_arn \
            --memory-size 256 --timeout 300 \
            --environment "Variables={REGION=$Region, FROM=$fromMail, FILE=$file, RECIPIENTS=${ARRAY[*]}, }" \
            --region $Region \
            --query 'FunctionArn' --output text`
      echo "Lambda Function "$function_arn" created successfully" 
fi

echo "**************************Event_Rule*****************************"
aws events describe-rule --name "$3" --region $Region > /dev/null 2>&1
if [ 0 -eq $? ]; then
echo "Event Rule '$3' already exists"
else
      echo "Event Rule '$3' Creating...."
      aws events put-rule --name "$3" --schedule-expression  "cron(46 05 * * ? *)" --region $Region
      aws events put-targets --rule "$3" --targets "Id"="1","Arn"=${function_arn} --region $Region
      
      echo "Event_Rule created successfully" 
fi



