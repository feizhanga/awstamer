 # Configure the module according to your needs
from datadog import initialize

options = {
     'api_key':'1d56**',
     'app_key':'d125**'
}

initialize(**options)

 # Use Datadog REST API client
from datadog import api

title = "Something happened AWSFZ"
text = 'And let me tell you all about it here!'
tags = ['version:1', 'Pythonapp:Sentinel:Npp']

api.Event.create(title=title, text=text, tags=tags)
