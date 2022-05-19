import requests
import json

#remove https warning
requests.packages.urllib3.disable_warnings()

def post(target, user_input, command):
   headers = {
            'content-type': "application/json",
            'Accept': "*/*",
        }
   data = json.dumps({"data" : user_input, "command" : command})
   response = requests.post(target, headers=headers, data=data,verify=False)
   print (response.content)

#Input target
target = input("Target: ")
user_input = input("Enter your message here: ")
command =  input("Enter your command here: ")
post(target, user_input, command)
