# экспортируем плагин
module.exports = (recess) ->
	# инициализируем плагин
	plugin = {}

	# добавляем в плагин функции для операций с файлами ("трубы")
	plugin.pipes =
		header: (header) ->
			# преобразовать заголовок в буффер
			bh = Buffer.from header 

			# преобразовать входные файлы в буфферы
			recess.i.buffer (files, cond) ->
				# асинхронная обработка файлов
				await recess.d.eachAsync files, (file) ->
					# соединить заголовок с содержанием файла
					file.contents = Buffer.concat [bh, file.contents]

				return files

		footer: (settings) ->
			# преобразовать входные файлы в буфферы
			recess.i.buffer (files, cond) ->
				b = Buffer.from settings
				await recess.d.eachAsync files, (file) ->
					file.contents = Buffer.concat [file.contents, b]
				files


	return plugin
