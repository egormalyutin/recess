cluster     = require 'cluster'
chalk       = require 'chalk'
up          = require 'find-up'
fs          = require 'fs-extra'
gaze        = require 'gaze'
process     = require 'process'
path        = require 'path'
coffee      = require 'coffeescript'

d = (argv) ->

	path    = require 'path'
	fs      = require 'fs-extra'
	program = require 'commander'

	# FIND PACKAGE.JSON
	pjPath   = path.resolve(__dirname, '../package.json')
	pjText   = (await fs.readFile pjPath).toString()
	pj       = JSON.parse pjText

	program
		.version pj.version
		.usage '[options] <task ...>'
		.option '-w, --watch',            'Look after files'
		.option '-c, --config <path>',    'Set config'
		.option '-b, --builder',          'Start builder'
		.option '-p, --production',       'Production mode'
		.option '-s, --silent',           'Disable logs'
		.parse argv


	# GET DATE
	time = ->
		dt = new Date

		hours = dt.getHours()
		hoursString = hours + ""
		hoursString = "0" + hoursString if hoursString.length is 1 

		minutes = dt.getMinutes()
		minutesString = minutes + ""
		minutesString = "0" + minutesString if minutesString.length is 1

		seconds = dt.getSeconds()
		secondsString = seconds + ""
		secondsString = "0" + secondsString if secondsString.length is 1 

		"#{hoursString}:#{minutesString}:#{secondsString}"


	# CONFIG NOT FOUND MESSAGE
	notFound = () ->
		console.log()
		console.log "  #{chalk.bold.red time()}   #{chalk.red '»'} #{chalk.bold 'Config not found!'}"
		console.log()
		process.exit()

	notFile = (path) ->
		console.log()
		console.log "  #{chalk.bold.red time()}   #{chalk.red '»'} #{chalk.bold path + ' is not a file!'}"
		console.log()
		process.exit()



	# FIND CONFIG
	cwd = process.cwd()
	if program.config
		pth = program.config
	else
		pth = try await up ['Recess.js', 'recess.js', 'Recess.coffee', 'recess.coffee'], {cwd}

	unless pth
		notFound()

	# check that config is file
	unless (await fs.stat(pth)).isFile()
		notFile pth

	# START MASTER
	if cluster.isMaster and program.builder
		worker = cluster.fork()
		onMessage = (msg) ->
			if msg is 'BUILD FINISHED'
				process.exit()
		worker.on 'message', onMessage


		upd = () ->
			console.log()
			console.log "  #{chalk.bold time()}   #{chalk.grey '»'} #{chalk.bold 'Config was changed!'}"
			worker.destroy()
			worker = cluster.fork()
			worker.on 'message', onMessage

		console.log()
		console.log "  #{chalk.bold time()}   #{chalk.grey '»'} #{chalk.bold 'Starting builder...'}"

		# WATCH CONFIG
		gaze pth, (err) ->
			console.error err if err

			@on 'delete', ->
				console.log "  #{chalk.bold.red time()}   #{chalk.red '»'} #{chalk.bold 'Config was deleted!'}"

			@on 'changed', (path) -> 
				upd()



	# START CHILD PROCESS TO KILL IT AFTER :X
	else

		run  = require './box.js'
		init = require './main.js'

		start = =>
			recess = init pth, cwd

			recess.production = !!program.production
			recess.silent     = !!program.silent

			use = (all) ->
				if all == recess.s.all
					nm = up.sync ["node_modules"], cwd: path.dirname(pth)
					unless nm
						recess.r.noNodeModules()

					packages = []
					rg = /^recess-/
					for pkg in fs.readdirSync(nm)
						if rg.test pkg
							packages.push path.join(nm, pkg)

					recess.use packages
				else
					recess.use arguments...

			# bridge
			dsl =
				recess: recess

				use:  use
				uses: use

				task:    recess.task
				tasks:   recess.task

				spawn:   recess.run
				run:     recess.run

				watch:   recess.watch
				watches: recess.watch
				ignore:  recess.ignore
				ignores: recess.ignore

				seq:      recess.seq
				sequence: recess.seq
				event:    recess.e
				e:        recess.e

				read: fs.readFileSync

				reporter: recess.reporter
				r:        recess.reporter
				message:  recess.reporter.message
				log:      recess.reporter.message
				err:      recess.reporter.fatal
				error:    recess.reporter.fatal
				end:      recess.reporter.end
				warn:     recess.reporter.warn

				console:
					message:  recess.reporter.message
					log:      recess.reporter.message
					info:     recess.reporter.message

					warn:     recess.reporter.warn

					err:      recess.reporter.fatal
					error:    recess.reporter.fatal

					info:     recess.reporter.dir

					end:      recess.reporter.end


				production: recess.production
				prod:       recess.production
				p:          recess.production

				outFile: recess.p.outFile
				outDir:  recess.p.outDir

				plugins: recess.plugins
				p:       recess.p
				to:      recess.p.to
				
				bundle:  recess.p.bundle

				wrap:   recess.p.wrap
				unwrap: recess.p.unwrap

				del:    recess.p.del
				remove: recess.p.remove

				min:    recess.p.min()
				minify: recess.p.min()

				cluster: recess.p.if
				pif:     recess.p.if

				stat:  recess.p.stat
				stats: recess.p.stat

				add:   recess.p.add
				ensureFiles: recess.p.add
				ensureAll:   recess.p.add

				concat: recess.p.concat
				con:    recess.p.concat
				
				ifWatch: recess.p.ifWatch

				convert: recess.p.convert
				to:      recess.p.convert
				compile: recess.p.compile()

				entry:    recess.s.entry
				entries:  recess.s.entry
				input:    recess.s.entry
				inputs:   recess.s.entry

				def:      recess.s.default
				defs:     recess.s.default
				default:  recess.s.default
				defaults: recess.s.default

				all: recess.s.all

			code = (await fs.readFile(pth)).toString()

			# preprocess CoffeeScript
			if recess.d.getExt(pth) == "coffee"
				code = coffee.compile code

			try
				run code, dsl
			catch e
				recess.r.error e

			ts = program.args

			ts = ['default'] if (ts.length is 0) and (not program.watch) and recess._tasks.default?
			ts = ['default'] if (ts.length is 0) and (    program.watch) and recess._tasks.default?
			ts = ['watch']   if (ts.length is 0) and (    program.watch) and recess._tasks.watch?


			if program.watch
				await recess.startWatch ts
			else
				await recess.startRun ts

		await start()

module.exports = d
