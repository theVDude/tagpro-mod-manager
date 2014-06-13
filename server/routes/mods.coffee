# Dependencies
nodemailer = require "nodemailer"
mongoose   = require "mongoose"
utils      = require "../utils"

# Email setup
mail_transport = nodemailer.createTransport "Direct", {}
admin_emails = [
	"rb.cubed@gmail.com"
]

# Import schemas
Mod = mongoose.models.Mod

module.exports = {}

module.exports.get = (req, res) ->
	Mod.find {accepted: true}, "name author", (err, results) ->

		throw new Error("Error loading mod list") if err
		
		if results.length is 0
			res.json error: "No mods found"
		else
			pojos = []
			for mod, k in results
				mod.getThumbnail ((mod, url) ->
					mobj = mod.toObject()
					mobj.thumbnail = url
					pojos.push mobj

					if pojos.length is results.length
						res.json pojos
				).bind this, mod

last_post = {}

module.exports.post = (req, res) ->
	# Request format (JSON):
	# All required!
	# 
	# name: "Any String" (unique)
	# author: "Reddit username"
	
	unless req.body.name? and req.body.author? and req.body.files.tiles?
		res.status 400
		return res.json
			error: "You didn't submit all required fields"

	if last_post[req.ip]?
		time = last_post[req.ip]

		if new Date().getTime() - time.getTime() < ( 5 * 1000 ) # 5 seconds, debug value
			res.status 429
			return res.json error: "You can't submit multiple mods within 10 minutes"
			return

	# All good!
	last_post[req.ip] = new Date()

	mod = new Mod
		name: req.body.name
		author: req.body.author
		files: req.body.files

	# Save to mongodb
	mod.save (err) ->
		if (err)
			res.status 500
			return res.json error: "Unknown database error occoured"
		else
			res.status 201
			res.json {}

			# Email admins about the new mod
			for k, email of admin_emails
				message =
					from: "TagPro Mod Manager <jamie@kwiius.com>"
					to:   "TPMM Admins <#{email}>"
					subject: "Review mod: #{mod.name}"
					html: """
					<h1>#{mod.name}</h1>
					<h3>By #{mod.author}</h3>
					<p>IP address: #{req.ip}</p>
					"""

				mail_transport.sendMail message, (err, response) ->
					if (err) then console.error "Error emailing admin (#{email}})"
					else console.log "Emailed admin #{email} about #{mod.name}"
