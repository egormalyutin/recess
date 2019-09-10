module.exports = (recess) ->
	reporter = recess.reporter
	plugin = {}
	plugin.pipes =
		convert: (settings, tr) ->
			if typeof settings not in ['number', 'string']
				reporter.fatal 'Setting must be a number or string!'


			recess.i.buffer (files, cond) ->
				r = await recess.d.mapAsync files, (file) ->
					ext = recess.d.getType file

					# if there's needed converter
					if recess.converters[ext] and recess.converters[ext][settings]

						pipe = recess.converters[ext][settings]

						collection = recess.collection [file], cond
						await collection.pipe pipe

						file = collection.files[0]
						file.setExt settings

						# pipe file
						return file
					else if ext is settings
						return file
					else if tr
					else
						# remove file
						reporter.noConverter file.path, settings
						return file
				r

		compile: ->
			recess.i.buffer (files, cond) ->
				r = await recess.d.mapAsync files, (file, n) ->
					ext = recess.d.getType file

					# if there's needed converter
					conv = recess.converters[ext]

					if conv and pipe = conv[Object.keys(conv)[0]]
						collection = recess.collection [file], cond
						await collection.pipe pipe

						file = collection.files[0]
						file.setExt Object.keys(conv)[0]

						files[n] = undefined

						# pipe file
						return file
					else if conv and ext is Object.keys(conv)[0]
						return file
					else
						# remove file
						reporter.noCompiler file.path
						return file
				r


	plugin.pipes.to = plugin.pipes.ex = plugin.pipes.convert

	plugin
