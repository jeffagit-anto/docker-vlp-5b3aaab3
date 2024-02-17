import md5
def md5_digest(key):
	return md5.new(str(key)).hexdigest()
