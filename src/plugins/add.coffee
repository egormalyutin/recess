path     = require 'path'
fs       = require 'fs-extra'
globby   = require 'globby'
ignore   = require 'ignore'

module.exports = (recess) ->
	reporter = recess.reporter
	plugin = {}
	plugin.pipes =
		add: (settings, force) =>
				settings = [settings] unless Array.isArray settings

				# PIPE #
				recess.i.any (files, cond) ->
					# get paths
					unless settings.length is 0
						ig = ignore().add recess.ignored
						glb   = globby.sync settings, cwd: cond.workdir
						paths = ig.filter glb

						# no files at input
						if (paths.length is 0) and (glb.length is paths.length)
							reporter.noFiles settings

						# load files
						await recess.d.eachAsync paths, (pth) ->
							pth = path.resolve cond.workdir, pth
							if force or not files.some (fl) -> path.resolve(cond.workdir, fl.path) is pth
								contents = await fs.readFile(path.resolve cond.workdir, pth)
								files.push new recess.File pth, contents

					files

	plugin.pipes.load = plugin.pipes.add

	plugin
