module.exports = (recess) ->
	all = -> return all
	s =
		entry:      { }
		default:    Symbol 'some default value'
		isSequence: Symbol 'some sequence of tasks'
		isEvent:    Symbol 'event.' 
		all:        all

	s.entry.outFile = s.entry

	recess.s = recess.symbols = s