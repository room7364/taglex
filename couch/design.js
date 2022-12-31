function(doc) {
	if (doc.back.answers) {
		for (var i in doc.back.answers) {
			words = doc.back.answers[i].match(/[^_\W]+/g)
			for (var j in words) {
				emit(words[j], null)
			}
		}
	}
}
