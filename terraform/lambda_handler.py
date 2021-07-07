import boto3
import csv
import os
import re 

from email import encoders
from email.mime.base import MIMEBase
from email.mime.application import MIMEApplication
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText

region =os.environ.get('REGION')
source =os.environ.get('FROM')
filename="/tmp/"+os.environ.get('FILE')  
destination =os.environ.get('TO')


field_names = ['Region','ResourceType','ResourceArn', 'TagKey', 'TagValue']

def writeToCsv(writer, filename, tag_list, reg):
    for resource in tag_list:
        a=re.split(r":|/", resource['ResourceARN'])
        if(not resource['Tags']):
            row = dict(
                  Region=reg, ResourceType=a[5],ResourceArn=resource['ResourceARN'], TagKey="NotTagged", TagValue="NotTagged")
            writer.writerow(row)
        else:
            for tag in resource['Tags']:
                row = dict(
                    Region=reg, ResourceType=a[5],ResourceArn=resource['ResourceARN'], TagKey=tag['Key'], TagValue=tag['Value'])
                writer.writerow(row)

def send_email_with_attachment():
    msg = MIMEMultipart()
    msg["Subject"] = "This is an email with an attachment!"
    msg["From"] = source
    msg["To"] = source

    body = MIMEText("Please find attached an excel document which contains all AWS Tagged and Previously Tagged Resources", "plain")
    msg.attach(body)

    with open(filename, "rb") as attachment:
        part = MIMEApplication(attachment.read())
        part.add_header("Content-Disposition",
                        "attachment",
                        filename=filename)
    msg.attach(part)

    ses_client = boto3.client("ses", region_name=region)
    response = ses_client.send_raw_email(
        Source=source,
        Destinations=[destination],
        RawMessage={"Data": msg.as_string()}
    )
    print(response)
def lambda_handler(event, context):
    ec2_client = boto3.client('ec2',region_name=region)
    regions = ec2_client.describe_regions()
    regions_data = regions['Regions']
    with open(filename, 'w') as csvfile:
        writer = csv.DictWriter(csvfile, quoting=csv.QUOTE_ALL, delimiter=',', dialect='excel', fieldnames=field_names)
        writer.writeheader()
        for reg in regions_data:
            client = boto3.client('resourcegroupstaggingapi',reg['RegionName'])
            response = client.get_resources(ResourcesPerPage=100)
            writeToCsv(writer, filename, response['ResourceTagMappingList'],reg['RegionName'])
              
    send_email_with_attachment()
    return "Success"
 
