#!/usr/bin/python
#
# submitPlugins.py: Submits plugins to the DMDirc addons site
#
# Copyright (c) 2006-2015 DMDirc Developers
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

from optparse import OptionParser
from zipfile import ZipFile
import glob
import os.path
import requests

# Configure the command-line options parser and read the options
parser = OptionParser(usage="usage: %prog [options] <files...>")
parser.add_option("-c", "--channel",
	dest="channel",
	help="Channel to submit the plugin to",
	default="STABLE",
	type="choice",
	choices=["STABLE", "UNSTABLE", "NIGHTLY"],
	metavar="CHANNEL")
parser.add_option("-k", "--keyfile",
	dest="apikey",
	help="File containing the API key to use for the DMDirc addons site",
	metavar="API_KEY_FILE")
(options, args) = parser.parse_args()

# Gather a set of matching files, and bail out if we can't find any
files = [filename for pattern in args for filename in glob.glob(pattern)]
if not files:
	parser.error("no input files found")

# See if the user specified an API key, if not try to read it from a local file
filename = "addons.api.key" if not options.apikey else options.apikey
with file(filename) as f:
	key = f.read().strip()

# Convert the channel into an arbitrary number
# TODO: The site should accept textual channel descriptions
channels = {"STABLE": 1, "UNSTABLE": 2, "NIGHTLY": 3}
channel = channels[options.channel]

def get_plugin_info(text):
	addon_id = None
	version = None
	domain = None

	for line in [line.strip() for line in text.splitlines()]:
		if line.endswith(":"):
			domain = line[:-1]
		elif "=" in line and domain in ["version", "updates"]:
			(key, value) = line.split("=", 2)
			if domain == "version" and key == "number":
				version = value
			elif domain == "updates" and key == "id":
				addon_id = value;

	return (addon_id, version)

# Now the actual work begins...
for filename in files:
	with ZipFile(filename, 'r') as jar:
		with jar.open('META-INF/plugin.config') as c:
			(id, version) = get_plugin_info(c.read())

	print "Submitting %s version %s .... " % (filename, version)

	r = requests.post("http://addons.dmdirc.com/editaddon/%s" % id,
		files = {"download": open(filename, 'rb')},
		data = {"apikey": key, "channel": channel})

	if r.status_code == requests.codes.ok:
		print "Submitted successfully"
	else:
		print "Submission FAILED"
