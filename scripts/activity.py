import requests

#remove https warning
requests.packages.urllib3.disable_warnings()

def post(target, user_input, command):
   headers = {
            'content-type': "application/json",
            'Accept': "*/*",
        }
   response = requests.post(target, data={'data' : user_input, 'command' : command},verify=False)
   print (response.content)

#Input target
target = input("Target: ")
user_input = input("Enter your message here: ")
command =  input("Enter your command here: ")
post(target, user_input, command)
