use 'recess-uglify'

tasks
	js: ->
		await @ add ['lib/**/*.js']
		await @ min
		await @ outDir 'out'
