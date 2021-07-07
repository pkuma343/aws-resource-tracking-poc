import boto3

MAIL_IDS = []
choice = "yes"

region = input("Please Enter a Region: ")
print(region)
while(choice == "yes"):
    to = input("Please Enter Email address to verify: ")
    MAIL_IDS.append(to)
    choice = input("Do you wish to add more recipient's address? (Yes or No) : ").lower()
    print("You said yeah!")
print(MAIL_IDS)

def verify_email_identity():
    print("in Function")
    ses_client = boto3.client("ses", region_name = region)
    res = ses_client.list_verified_email_addresses()
    for id in MAIL_IDS:
        if id  not in res['VerifiedEmailAddresses']:
            response = ses_client.verify_email_identity(
                EmailAddress = id
            )
            print(response)
        else: print("Verified")

verify_email_identity()

