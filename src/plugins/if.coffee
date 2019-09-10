mm = require 'micromatch'

module.exports = (recess) ->
	reporter = recess.reporter
	plugin = {}
	plugin.pipes =
		pif: (settings) ->
			recess.i.any (files, cond) ->
				results = []
				unfiltered = files

				await recess.d.eachAsync settings, (pipe, filter) ->
					filtered = mm (file.path for file in files), filter
					rets = []
					for file in unfiltered
						if filtered.includes file.path
							rets.push file

					for ret in rets
						unfiltered = unfiltered.filter ({path}) -> not filtered.some (pth) -> path is pth

					collection = recess.collection rets, cond
					await collection.pipe pipe
					file = collection.files[0]
					results.push file if file

				results.push unfiltered...

				return results
		
		ifWatch: (pipes) ->	
			pipes = [pipes] unless Array.isArray pipes

			recess.i.any (files, cond) ->
				return files unless cond.watching

				collection = recess.collection files, cond

				for pipe in pipes
					await collection.pipe pipe

				return collection.files

	plugin.pipes.if = plugin.pipes.cluster = plugin.pipes.switch = plugin.pipes.pif


	plugin
