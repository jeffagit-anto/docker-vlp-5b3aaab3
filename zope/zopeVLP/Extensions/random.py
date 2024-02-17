# Example code:

# Import a standard function, and get the HTML request and response objects.
from Products.PythonScripts.standard import html_quote

import time
import random
import md5
def keys():
	# random.seed()
	key= int(time.time()) # random.randint(0,1000099999)
	return key,md5.new(str(key)).hexdigest()
