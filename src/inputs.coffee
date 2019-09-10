sta = require 'stream-to-array'
stream = require 'stream'

module.exports = (recess) ->

	recess.i = recess.inputs = recess.input = {}

	type = (obj) ->
		if typeof obj is 'string'
			'string'
		else if Buffer.isBuffer obj
			'buffer'
		else if (typeof obj is 'object') and obj.pipe?
			'stream'
		else
			recess.reporter.error 'Unknown type of file contents!'

	recess.i.buffer = (f) ->
		(files) ->
			await recess.d.eachAsync files, (file, name) ->
				tp = type file.contents
				m = false

				if tp is 'string'
					m = true
					modified = Buffer.from file.contents

				else if tp is 'buffer'
					m = true
					modified = file.contents

				else if tp is 'stream'
					m = true
					arr = await sta file.contents
					arr = await recess.d.mapAsync arr, (contents) -> Buffer.from contents
					modified = Buffer.contents arr	

				if m
					files[name].contents = modified
				else
					files.splice name, 1

			f arguments...

	recess.i.string = (f) ->
		(files) ->
			await recess.d.eachAsync files, (file, name) ->
				tp = type file.contents
				m = false

				if tp is 'string'
					m = true
					modified = file.contents

				else if tp is 'buffer'
					m = true				
					modified = file.contents.toString()

				else if tp is 'stream'
					m = true
					arr = await sta file.contents
					arr = await recess.d.mapAsync arr, (contents) -> contents.toString()
					modified = arr.join ''

				# remove empty files
				if m
					files[name].contents = modified
				else
					files.splice name, 1

			f arguments...

	streamify = (b) ->
		s = new stream.Readable
		s.push b
		s.push null
		s

	recess.i.stream = (f) ->
		(files) ->
			await recess.d.eachAsync files, (file, name) ->
				tp = type file.contents
				m = false

				if tp is 'string'
					m = true
					modified = streamify file.contents

				else if tp is 'buffer'
					m = true
					modified = streamify file.contents

				else if tp is 'stream'
					m = true
					modified = file.contents

				if m
					files[name].contents = modified
				else
					files.splice name, 1

			f arguments...

	recess.i.any = (f) ->
		(files) ->
			await recess.d.eachAsync files, (file, name) ->
				unless file
					files.splice name, 1
			f arguments...


